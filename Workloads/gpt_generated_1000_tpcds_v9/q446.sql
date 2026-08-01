WITH joined_data AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        td.t_sub_shift,
        cp.cp_catalog_number,
        i.i_current_price,
        hd.hd_income_band_sk,
        p.p_channel_demo,
        wr.wr_return_quantity,
        wr.wr_return_amt
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    FULL OUTER JOIN web_returns wr
        ON i.i_item_sk = wr.wr_item_sk
           AND td.t_time_sk = wr.wr_returned_time_sk
    WHERE td.t_sub_shift = 'morning'
      AND cp.cp_catalog_number BETWEEN 10 AND 20
      AND i.i_current_price > 20.0
      AND hd.hd_income_band_sk IN (5, 6, 7)
      AND p.p_channel_demo = 'N'
      AND cs.cs_quantity >= 2
),

item_agg AS (
    SELECT
        cs_item_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        SUM(cs_quantity) AS total_quantity,
        SUM(COALESCE(wr_return_quantity, 0)) AS total_return_qty,
        SUM(COALESCE(wr_return_amt, 0.0)) AS total_return_amt
    FROM joined_data
    GROUP BY cs_item_sk
),

high_sales AS (
    SELECT cs_item_sk
    FROM item_agg
    WHERE total_sales > 1000
),

low_sales AS (
    SELECT cs_item_sk
    FROM item_agg
    WHERE total_sales <= 1000 AND total_quantity > 5
),

union_items AS (
    SELECT cs_item_sk FROM high_sales
    UNION
    SELECT cs_item_sk FROM low_sales
),

has_returns AS (
    SELECT cs_item_sk
    FROM item_agg
    WHERE total_return_qty > 0
),

sales_and_returns AS (
    SELECT cs_item_sk FROM union_items
    INTERSECT
    SELECT cs_item_sk FROM has_returns
),

final AS (
    SELECT
        ia.cs_item_sk,
        ia.total_sales,
        ia.total_profit,
        ia.total_quantity,
        ia.total_return_qty,
        ia.total_return_amt,
        ROW_NUMBER() OVER (ORDER BY ia.total_sales DESC) AS rn
    FROM item_agg ia
    WHERE ia.cs_item_sk IN (SELECT cs_item_sk FROM sales_and_returns)
)

SELECT
    cs_item_sk,
    total_sales,
    total_profit,
    total_quantity,
    total_return_qty,
    total_return_amt,
    rn
FROM final
ORDER BY total_sales DESC
LIMIT 100
