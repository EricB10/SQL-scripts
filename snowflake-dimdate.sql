-- Create DIM_DATE table for date range 2000-2049. Requires existing table of US holidays.
-- Snowflake syntax, check the first "day of week" if using different database.

create or replace table "DIM_DATE"."PUBLIC"."DIM_DATE" (
    "DATE" date not null
    , "DATE_INT" int not null
    , "YEAR" int not null
    , "MONTH" int not null
    , "DAY" int not null
    , "DAYOFYEAR" int not null
    , "WEEKOFYEAR" int not null
    , "DAYOFWEEK" int not null
    , "YTD" int not null
    , "YTD_PREV_YR" int not null
    , "MTD" int not null
    , "MTD_PREV_YR" int not null
    , "WTD" int not null
    , "WTD_PREV_YR" int not null
    , "HOLIDAY" varchar(100)
    , unique("DATE", "DATE_INT")
    , primary key("DATE", "DATE_INT")
) as (

    with "DATES" as (
        select to_date(dateadd(day, seq4(), '2000-01-01')) as "DATE"
        from table(generator(rowcount=>20000))
        where "DATE" < '2050-01-01'
    )
    , "COMP_DATE" as (
        select
            "DATE" as "COMP_DATE"
            , case
                when weekofyear(current_date()) = 53
                    then 52
                else weekofyear(current_date())
            end as "COMP_WEEK"
        from "DATES"
        where year("COMP_DATE") = year(current_date()) - 1
        and weekofyear("COMP_DATE") = "COMP_WEEK"
        and dayofweek("COMP_DATE") = dayofweek(current_date())
    )

    select
        d."DATE"
        , year(d."DATE")*10000 + month(d."DATE")*100 + day(d."DATE") as "DATE_INT"
        , year(d."DATE") as "YEAR"
        , month(d."DATE") as "MONTH"
        , day(d."DATE") as "DAY"
        , dayofyear(d."DATE") as "DAYOFYEAR"
        , weekofyear(d."DATE") as "WEEKOFYEAR"
        , dayofweek(d."DATE") as "DAYOFWEEK"
        , case
            when dayofyear(d."DATE") <= dayofyear(current_date())
            and year(d."DATE") = year(current_date())
                then 1
            else 0
        end as "YTD"
        , case
            when dayofyear(d."DATE") <= dayofyear(current_date())
            and year(d."DATE") = year(current_date()) - 1
                then 1
            else 0
        end as "YTD_PREV_YR"
        , case
            when month(d."DATE") = month(current_date())
            and dayofyear(d."DATE") <= dayofyear(current_date())
            and year(d."DATE") = year(current_date())
                then 1
            else 0
        end as "MTD"
        , case
            when month(d."DATE") = month(current_date())
            and dayofyear(d."DATE") <= dayofyear(current_date())
            and year(d."DATE") = year(current_date()) - 1
                then 1
            else 0
        end as "MTD_PREV_YR"
        , case
            when weekofyear(d."DATE") = weekofyear(current_date())
            and d."DATE" - current_date() <= 0
            and d."DATE" - current_date() >= -6
                then 1
            else 0
        end as "WTD"
        , case
            when weekofyear(d."DATE") = weekofyear(c."COMP_DATE")
            and d."DATE" - c."COMP_DATE" <= 0
            and d."DATE" - c."COMP_DATE" >= -6
                then 1
            else 0
        end as "WTD_PREV_YR"
        , h."HOLIDAY"
    from "DATES" as d
    join "COMP_DATE" as c on 1=1
    left join "DIM_DATE"."PUBLIC"."US_HOLIDAYS" as h on h."DATE" = d."DATE"
    order by d."DATE"

);