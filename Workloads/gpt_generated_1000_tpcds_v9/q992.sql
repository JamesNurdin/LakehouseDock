WITH cs_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name AS warehouse_name,
        w.w_city AS city,
        t_cs.t_shift AS shift,
        SUM(cs.cs_net_profit) AS catalog_profit,
        COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p_cat
        ON cs.cs_promo_sk = p_cat.p_promo_sk
    JOIN ship_mode sm_cat
        ON cs.cs_ship_mode_sk = sm_cat.sm_ship_mode_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        t_cs.t_shift = 'first'
        AND i.i_category = 'Sports'
        AND w.w_city = 'Lincoln'
        AND p_cat.p_discount_active = 'Y'
        AND cd_bill.cd_gender = 'M'
        AND ib.ib_upper_bound >= 60000
        AND EXISTS (
            SELECT 1
            FROM call_center cc
            WHERE cc.cc_call_center_sk = cs.cs_call_center_sk
              AND cc.cc_state = 'CA'
        )
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_city, t_cs.t_shift
),
ws_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name AS warehouse_name,
        w.w_city AS city,
        t_ws.t_shift AS shift,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_returns,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    WHERE
        t_ws.t_shift = 'first'
        AND i.i_category = 'Sports'
        AND w.w_city = 'Lincoln'
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_city, t_ws.t_shift
)
SELECT
    COALESCE(cs.warehouse_name, ws.warehouse_name) AS warehouse_name,
    COALESCE(cs.city, ws.city) AS city,
    COALESCE(cs.shift, ws.shift) AS shift,
    cs.catalog_profit,
    ws.web_profit,
    ws.total_returns,
    (COALESCE(cs.catalog_profit, 0) + COALESCE(ws.web_profit, 0) - COALESCE(ws.total_returns, 0)) AS net_total_profit,
    RANK() OVER (
        PARTITION BY COALESCE(cs.shift, ws.shift)
        ORDER BY (COALESCE(cs.catalog_profit, 0) + COALESCE(ws.web_profit, 0) - COALESCE(ws.total_returns, 0)) DESC
    ) AS profit_rank
FROM cs_agg cs
FULL OUTER JOIN ws_agg ws
    ON cs.w_warehouse_sk = ws.w_warehouse_sk
   AND cs.shift = ws.shift
ORDER BY shift, profit_rank
LIMIT 100
