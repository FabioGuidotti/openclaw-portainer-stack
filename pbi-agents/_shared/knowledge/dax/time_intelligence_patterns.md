# Time Intelligence Patterns

> All patterns below REQUIRE a proper Date dimension table marked as Date Table.

## Year-To-Date (YTD)

```dax
Sales YTD = TOTALYTD(SUM(Fact_Sales[SalesAmount]), Dim_Date[Date])
```

## Same Period Last Year

```dax
Sales SPLY = 
CALCULATE(
    SUM(Fact_Sales[SalesAmount]),
    SAMEPERIODLASTYEAR(Dim_Date[Date])
)
```

## Year-Over-Year Growth

```dax
Sales YoY % = 
VAR CurrentYear = SUM(Fact_Sales[SalesAmount])
VAR PriorYear = CALCULATE(
    SUM(Fact_Sales[SalesAmount]),
    SAMEPERIODLASTYEAR(Dim_Date[Date])
)
RETURN
    IF(
        NOT ISBLANK(PriorYear),
        DIVIDE(CurrentYear - PriorYear, PriorYear),
        BLANK()
    )
```

## Month-Over-Month

```dax
Sales MoM % =
VAR CurrentMonth = SUM(Fact_Sales[SalesAmount])
VAR PriorMonth = CALCULATE(
    SUM(Fact_Sales[SalesAmount]),
    DATEADD(Dim_Date[Date], -1, MONTH)
)
RETURN
    IF(
        NOT ISBLANK(PriorMonth),
        DIVIDE(CurrentMonth - PriorMonth, PriorMonth),
        BLANK()
    )
```

## Rolling 12 Months

```dax
Sales R12M = 
CALCULATE(
    SUM(Fact_Sales[SalesAmount]),
    DATESINPERIOD(Dim_Date[Date], MAX(Dim_Date[Date]), -12, MONTH)
)
```

## Moving Average (3 Months)

```dax
Sales MA3 = 
AVERAGEX(
    DATESINPERIOD(Dim_Date[Date], MAX(Dim_Date[Date]), -3, MONTH),
    CALCULATE(SUM(Fact_Sales[SalesAmount]))
)
```

## Date Table Template (Power Query M)

```m
let
    StartDate = #date(2020, 1, 1),
    EndDate = #date(2030, 12, 31),
    DateList = List.Dates(StartDate, Duration.Days(EndDate - StartDate) + 1, #duration(1,0,0,0)),
    DateTable = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}, null, ExtraValues.Error),
    #"Changed Type" = Table.TransformColumnTypes(DateTable, {{"Date", type date}})
in
    #"Changed Type"
```
