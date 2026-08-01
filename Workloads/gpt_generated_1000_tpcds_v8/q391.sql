WITH sales_union AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_sold_time_sk AS sold_time_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_bill_cdemo_sk AS cdemo_sk,
        cs.cs_bill_hdemo_sk AS hdemo_sk,
        cs.cs_bill_addr_sk AS addr_sk,
        cs.cs_ship_mode_sk AS ship_mode_sk,
        cs.cs_warehouse_sk AS warehouse_sk,
        NULL AS store_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_order_number AS order_number,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        'catalog' AS sales_source
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10)
    WHERE cs.cs_net_paid > 100
      AND cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2002)
),
store_union AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        NULL AS ship_mode_sk,
        NULL AS warehouse_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number AS order_number,
        ss.ss_net_paid,
        ss.ss_net_profit,
        'store' AS sales_source
    FROM store_sales ss
    WHERE ss.ss_net_paid > 100
      AND ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2002)
),
sales_all AS (
    SELECT * FROM sales_union
    UNION ALL
    SELECT * FROM store_union
),
web_page_cte AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        d.d_date_sk AS creation_date_sk,
        wp.wp_customer_sk
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
),
web_site_cte AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        d.d_date_sk AS open_date_sk
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
),
full_wp_ws AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        ws.web_site_sk,
        ws.web_name,
        COALESCE(wp.creation_date_sk, ws.open_date_sk) AS ref_date_sk
    FROM web_page_cte wp
    FULL OUTER JOIN web_site_cte ws
        ON wp.creation_date_sk = ws.open_date_sk
)
SELECT
    d.d_date,
    t.t_hour,
    c.c_customer_id,
    c.c_email_address,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    p.p_promo_name,
    sm.sm_type,
    w.w_warehouse_name,
    s.s_store_name,
    fw.wp_url,
    fw.web_name,
    su.sales_source,
    su.net_paid,
    su.net_profit,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY su.net_profit DESC) AS profit_rank
FROM sales_all su
JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
JOIN time_dim t ON su.sold_time_sk = t.t_time_sk
JOIN customer c ON su.customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON su.cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON su.hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p ON su.promo_sk = p.p_promo_sk
LEFT JOIN ship_mode sm ON su.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w ON su.warehouse_sk = w.w_warehouse_sk
LEFT JOIN store s ON su.store_sk = s.s_store_sk
LEFT JOIN full_wp_ws fw ON d.d_date_sk = fw.ref_date_sk
WHERE
    d.d_year = 2002
    AND cd.cd_gender = 'M'
    AND hd.hd_buy_potential = '1001-5000'
    AND ib.ib_lower_bound >= 20000
    AND p.p_channel_demo = 'N'
    AND (sm.sm_type = 'AIR' OR su.sales_source = 'store')
    AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = su.promo_sk
          AND p2.p_discount_active = 'Y'
    )
    AND NOT EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_order_number = su.order_number
    )
ORDER BY profit_rank
LIMIT 100
