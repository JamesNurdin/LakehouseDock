WITH filtered AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cp.cp_department,
        sm.sm_type AS cs_ship_mode_type,
        p.p_promo_name,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_buy_potential,
        td.t_hour,
        we.web_site_id,
        we.web_state,
        we.web_country,
        ws.ws_order_number,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        wp.wp_type,
        sr.sr_refunded_cash,
        sr.sr_return_quantity,
        r.r_reason_desc,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        r_wr.r_reason_desc AS wr_reason_desc
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_return_time_sk = td.t_time_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON wr.wr_returning_customer_sk = c.c_customer_sk
        AND wr.wr_returning_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_returning_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    RIGHT OUTER JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE cs.cs_quantity > 10
      AND cp.cp_department = 'Electronics'
      AND we.web_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1 FROM store_returns sr2
          WHERE sr2.sr_customer_sk = c.c_customer_sk
            AND sr2.sr_return_quantity > 0
      )
),
agg AS (
    SELECT
        web_site_id,
        web_state,
        web_country,
        cp_department,
        cs_promo_sk,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        AVG(sr_refunded_cash) AS avg_refunded_cash,
        MAX(wr_return_amt) AS max_return_amount
    FROM filtered
    GROUP BY web_site_id, web_state, web_country, cp_department, cs_promo_sk
),
ls AS (
    SELECT
        we.web_site_id,
        ls.total_site_sales
    FROM web_site we
    CROSS JOIN LATERAL (
        SELECT SUM(ws2.ws_ext_sales_price) AS total_site_sales
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = we.web_site_sk
    ) ls
)
SELECT
    a.web_site_id,
    a.web_state,
    a.cp_department,
    a.total_catalog_sales,
    a.total_web_sales,
    a.unique_customers,
    a.avg_refunded_cash,
    a.max_return_amount,
    (
        SELECT AVG(cs_inner.cs_ext_discount_amt)
        FROM catalog_sales cs_inner
        WHERE cs_inner.cs_promo_sk = a.cs_promo_sk
    ) AS avg_discount_per_promo,
    LAG(a.total_catalog_sales) OVER (PARTITION BY a.web_country ORDER BY a.total_catalog_sales DESC) AS lag_total_catalog_sales,
    ls.total_site_sales
FROM agg a
JOIN ls ON ls.web_site_id = a.web_site_id
CROSS JOIN (SELECT 1 AS grp UNION ALL SELECT 2) gen
ORDER BY a.total_catalog_sales DESC
LIMIT 100
