WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_net_paid) AS cs_total_net_paid,
        SUM(cs.cs_net_profit) AS cs_total_net_profit,
        SUM(cs.cs_quantity) AS cs_total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND w.w_gmt_offset = -5.00
      AND i.i_brand = 'Brand1'
    GROUP BY cs.cs_item_sk
),
cr_agg AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS cr_total_return_amount,
        SUM(cr.cr_net_loss) AS cr_total_net_loss,
        COUNT(*) AS cr_return_count
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2000
      AND r.r_reason_id = 'AAAAAAAACAAAAAAA'
    GROUP BY cr.cr_item_sk
),
sr_agg AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_amt) AS sr_total_return_amt,
        SUM(sr.sr_net_loss) AS sr_total_net_loss,
        COUNT(*) AS sr_return_count
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND i.i_color = 'Red'
      AND sr.sr_return_quantity > 0
    GROUP BY sr.sr_item_sk
),
ws_agg AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_net_paid) AS ws_total_net_paid,
        SUM(ws.ws_net_profit) AS ws_total_net_profit,
        SUM(ws.ws_quantity) AS ws_total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND w.w_gmt_offset = -5.00
      AND ws.ws_quantity > 1
    GROUP BY ws.ws_item_sk
),
wr_exists AS (
    SELECT DISTINCT wr.wr_item_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2000
      AND r.r_reason_id = 'AAAAAAAACAAAAAAA'
)
SELECT
    i.i_item_id,
    i.i_product_name,
    cs_agg.cs_total_net_paid,
    cs_agg.cs_total_net_profit,
    ws_agg.ws_total_net_paid,
    ws_agg.ws_total_net_profit,
    cr_agg.cr_total_return_amount,
    sr_agg.sr_total_return_amt,
    CASE
        WHEN COALESCE(cs_agg.cs_total_net_profit, 0) + COALESCE(ws_agg.ws_total_net_profit, 0)
             - COALESCE(cr_agg.cr_total_net_loss, 0) - COALESCE(sr_agg.sr_total_net_loss, 0) > 10000 THEN 'High'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (
        ORDER BY (COALESCE(cs_agg.cs_total_net_profit, 0) + COALESCE(ws_agg.ws_total_net_profit, 0)
                  - COALESCE(cr_agg.cr_total_net_loss, 0) - COALESCE(sr_agg.sr_total_net_loss, 0)) DESC
    ) AS profit_rank
FROM item i
LEFT JOIN cs_agg ON i.i_item_sk = cs_agg.cs_item_sk
LEFT JOIN cr_agg ON i.i_item_sk = cr_agg.cr_item_sk
LEFT JOIN sr_agg ON i.i_item_sk = sr_agg.sr_item_sk
LEFT JOIN ws_agg ON i.i_item_sk = ws_agg.ws_item_sk
WHERE i.i_item_sk IN (SELECT wr_item_sk FROM wr_exists)
ORDER BY profit_rank
LIMIT 100
