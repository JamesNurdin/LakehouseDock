WITH cs AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_call_center_sk IN (
        SELECT cc_call_center_sk FROM call_center WHERE cc_state = 'CA'
    )
),
cr AS (
    SELECT *
    FROM catalog_returns
    WHERE cr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
),
ws AS (
    SELECT *
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
),
wr AS (
    SELECT *
    FROM web_returns
    WHERE wr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
)
SELECT
    cs.cs_order_number,
    d_sold.d_date AS sold_date,
    cc.cc_name AS call_center_name,
    sm.sm_carrier,
    w.w_warehouse_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    wp.wp_url,
    wep.web_name,
    cs.cs_net_profit,
    CASE WHEN cs.cs_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY d_sold.d_year ORDER BY cs.cs_net_profit DESC) AS profit_rank,
    cr.cr_return_amount,
    wr.wr_return_amt
FROM cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d_return_cr
    ON cr.cr_returned_date_sk = d_return_cr.d_date_sk
JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN warehouse w_cr
    ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
   AND ws.ws_item_sk = cs.cs_item_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wep
    ON ws.ws_web_site_sk = wep.web_site_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
JOIN date_dim d_return_wr
    ON wr.wr_returned_date_sk = d_return_wr.d_date_sk
WHERE
    sm.sm_carrier = 'BARIAN'
    AND wep.web_zip LIKE '84%'
    AND d_sold.d_year = 2001
    AND w.w_state = 'CA'
ORDER BY profit_rank
LIMIT 100
