WITH agg1 AS (
    SELECT
        d_sales.d_year AS year,
        d_sales.d_month_seq AS month_seq,
        cc.cc_state AS state,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returns,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_on_hand,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales
        ON cs.cs_sold_time_sk = t_sales.t_time_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN web_returns wr
        ON i.i_item_sk = wr.wr_item_sk
        AND wr.wr_returned_date_sk = d_sales.d_date_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
        AND inv.inv_date_sk = d_sales.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d_sales.d_date_sk
    WHERE
        d_sales.d_year = 2001                      -- filter 1: year
        AND i.i_category = 'Sports'                -- filter 2: product category
        AND cc.cc_state = 'CA'                     -- filter 3: call‑center state
        AND ws.web_country = 'USA'                 -- filter 4: web site country
        AND inv.inv_quantity_on_hand >= 10        -- filter 5: inventory threshold
    GROUP BY
        d_sales.d_year,
        d_sales.d_month_seq,
        cc.cc_state,
        i.i_category
)
SELECT
    year,
    month_seq,
    state,
    category,
    total_sales,
    total_profit,
    total_returns,
    total_inventory_on_hand,
    order_cnt,
    CASE WHEN total_profit > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
FROM agg1
WHERE total_sales > 10000                         -- additional filter on the derived aggregate
ORDER BY
    total_profit DESC,
    year,
    month_seq
LIMIT 100
