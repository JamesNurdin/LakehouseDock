WITH unified AS (
    SELECT
        i.i_category,
        i.i_brand,
        cs.cs_net_profit AS cs_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        ws.ws_quantity AS ws_quantity,
        cr.cr_return_amount AS cr_return_amount,
        cr.cr_return_quantity AS cr_return_quantity,
        sr.sr_return_amt AS sr_return_amt,
        sr.sr_return_quantity AS sr_return_quantity,
        wr.wr_return_amt AS wr_return_amt,
        wr.wr_return_quantity AS wr_return_quantity,
        c.c_customer_sk AS c_customer_sk,
        cc.cc_sq_ft AS cc_sq_ft,
        sm.sm_type AS sm_type,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand
    FROM item i
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returning_customer_sk = c.c_customer_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    WHERE cc.cc_sq_ft > 0
      AND i.i_current_price BETWEEN 50 AND 1000
      AND ca.ca_gmt_offset > -5.00
      AND inv.inv_quantity_on_hand < 5000
      AND cs.cs_net_profit > 0
      AND sm.sm_type = 'AIR'
),

agg1 AS (
    SELECT
        i_category,
        i_brand,
        COALESCE(SUM(cs_net_profit), 0) AS sum_cs_net_profit,
        COALESCE(SUM(ws_net_profit), 0) AS sum_ws_net_profit,
        COALESCE(SUM(cr_return_amount), 0) AS sum_cr_return_amount,
        COALESCE(SUM(sr_return_amt), 0) AS sum_sr_return_amt,
        COALESCE(SUM(wr_return_amt), 0) AS sum_wr_return_amt,
        COUNT(DISTINCT c_customer_sk) AS distinct_customers,
        (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_category = i_category) AS avg_price_in_category
    FROM unified
    WHERE cr_return_quantity > 0
    GROUP BY GROUPING SETS ((i_category, i_brand), (i_category), ())
),

agg2 AS (
    SELECT
        i_category,
        i_brand,
        COALESCE(SUM(cs_net_profit), 0) AS sum_cs_net_profit,
        COALESCE(SUM(ws_net_profit), 0) AS sum_ws_net_profit,
        COALESCE(SUM(cr_return_amount), 0) AS sum_cr_return_amount,
        COALESCE(SUM(sr_return_amt), 0) AS sum_sr_return_amt,
        COALESCE(SUM(wr_return_amt), 0) AS sum_wr_return_amt,
        COUNT(DISTINCT c_customer_sk) AS distinct_customers,
        (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_category = i_category) AS avg_price_in_category
    FROM unified
    WHERE sr_return_quantity > 0
      AND ws_quantity > 0
    GROUP BY GROUPING SETS ((i_category, i_brand), (i_category), ())
),

unioned AS (
    SELECT * FROM agg1
    UNION DISTINCT
    SELECT * FROM agg2
)

SELECT
    i_category,
    i_brand,
    sum_cs_net_profit,
    sum_ws_net_profit,
    sum_cr_return_amount,
    sum_sr_return_amt,
    sum_wr_return_amt,
    (sum_cs_net_profit + sum_ws_net_profit) - (sum_cr_return_amount + sum_sr_return_amt + sum_wr_return_amt) AS net_profit,
    distinct_customers,
    avg_price_in_category,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY ((sum_cs_net_profit + sum_ws_net_profit) - (sum_cr_return_amount + sum_sr_return_amt + sum_wr_return_amt)) DESC) AS rank_in_category
FROM unioned
ORDER BY i_category, rank_in_category
LIMIT 100
