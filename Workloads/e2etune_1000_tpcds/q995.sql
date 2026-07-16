WITH sales_agg AS (
    SELECT
        cs_item_sk,
        SUM(cs_net_paid_inc_ship) AS total_sales,
        SUM(cs_quantity) AS total_quantity,
        AVG(cs_net_paid_inc_ship) AS avg_sales_price,
        SUM(cs_ext_discount_amt) AS total_discount
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450000 AND 2450999
    GROUP BY cs_item_sk
),
returns_agg AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_qty,
        AVG(sr_return_amt) AS avg_return_amt
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2450000 AND 2450999
    GROUP BY sr_item_sk
),
combined AS (
    SELECT
        s.cs_item_sk,
        s.total_sales,
        COALESCE(r.total_return_amt, 0) AS total_return_amt,
        s.total_quantity,
        COALESCE(r.total_return_qty, 0) AS total_return_qty,
        s.avg_sales_price,
        r.avg_return_amt
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.cs_item_sk = r.sr_item_sk
)
SELECT
    cs_item_sk,
    total_sales,
    total_return_amt,
    (total_sales - total_return_amt) AS net_sales,
    (total_quantity - total_return_qty) AS net_quantity,
    avg_sales_price,
    avg_return_amt,
    CASE
        WHEN total_sales > 0 THEN (total_sales - total_return_amt) / total_sales * 100
        ELSE NULL
    END AS net_sales_pct,
    RANK() OVER (ORDER BY (total_sales - total_return_amt) DESC) AS sales_rank
FROM combined
ORDER BY net_sales DESC
LIMIT 100
