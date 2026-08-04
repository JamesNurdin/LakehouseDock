WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        i.i_category,
        i.i_brand,
        ws.ws_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(ws.ws_ext_sales_price)        AS total_sales,
        SUM(ws.ws_net_profit)               AS total_profit,
        COUNT(*)                            AS sale_cnt
    FROM web_sales ws
    JOIN item i                         ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c                     ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd       ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_ext_sales_price > 1000                -- predicate 1
      AND i.i_current_price < 5000                     -- predicate 2
      AND cd.cd_credit_rating = 'Good'                -- predicate 3
      AND hd.hd_income_band_sk BETWEEN 3 AND 8        -- predicate 4
    GROUP BY
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        i.i_category,
        i.i_brand,
        ws.ws_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk
),

returns_agg AS (
    SELECT
        wr.wr_order_number,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*)               AS return_cnt
    FROM web_returns wr
    JOIN web_sales ws        ON wr.wr_order_number = ws.ws_order_number
    JOIN item i              ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_return_amt > 0
    GROUP BY wr.wr_order_number
),

combined_orders AS (
    SELECT ws_order_number
    FROM (
        SELECT ws_order_number, total_profit
        FROM sales_agg
        WHERE total_profit > 5000
    )
    INTERSECT
    SELECT wr_order_number
    FROM (
        SELECT wr_order_number, total_return_amt
        FROM returns_agg
        WHERE total_return_amt < 200
    )
),

sales_with_returns AS (
    SELECT
        sa.ws_order_number,
        sa.i_category,
        sa.i_brand,
        sa.c_first_name,
        sa.c_last_name,
        sa.cd_gender,
        sa.hd_income_band_sk,
        sa.total_sales,
        sa.total_profit,
        COALESCE(ra.total_return_amt, 0) AS total_return_amt,
        (sa.total_sales - COALESCE(ra.total_return_amt, 0)) AS net_sales,
        sa.ws_item_sk
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.ws_order_number = ra.wr_order_number
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = sa.ws_order_number
          AND wr.wr_return_amt > 1000
    )
      AND sa.ws_order_number IN (SELECT ws_order_number FROM combined_orders)
),

ranked_sales AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_profit DESC) AS rank_in_category
    FROM sales_with_returns
),

union_set AS (
    SELECT
        i_category,
        i_brand,
        cd_gender,
        hd_income_band_sk,
        total_sales,
        total_profit,
        total_return_amt,
        net_sales
    FROM ranked_sales
    WHERE rank_in_category <= 5
    UNION DISTINCT
    SELECT
        i_category,
        i_brand,
        cd_gender,
        hd_income_band_sk,
        total_sales,
        total_profit,
        total_return_amt,
        net_sales
    FROM ranked_sales
    WHERE net_sales > 2000
)
SELECT
    i_category,
    i_brand,
    cd_gender,
    hd_income_band_sk,
    SUM(total_sales)        AS sum_sales,
    SUM(total_profit)       AS sum_profit,
    SUM(total_return_amt)   AS sum_return,
    SUM(net_sales)          AS sum_net_sales,
    (SELECT AVG(ws_ext_sales_price) FROM web_sales) AS overall_avg_sales_price
FROM union_set
GROUP BY ROLLUP (i_category, i_brand, cd_gender, hd_income_band_sk)
ORDER BY sum_profit DESC
LIMIT 100
