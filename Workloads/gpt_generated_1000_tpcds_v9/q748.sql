WITH base AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_net_loss,
        cr.cr_net_loss,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cc.cc_name,
        w.w_warehouse_name,
        ca.ca_state AS customer_state,
        ca.ca_country AS customer_country
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_country = 'United States'
      AND ib.ib_lower_bound >= 30000
      AND hd.hd_vehicle_count > 1
),
agg AS (
    SELECT
        b.ss_store_sk,
        b.ss_promo_sk,
        SUM(b.ss_net_paid) AS total_sales,
        SUM(b.ss_net_profit) AS total_profit,
        SUM(COALESCE(b.sr_net_loss, 0)) AS total_store_return_loss,
        SUM(COALESCE(b.cr_net_loss, 0)) AS total_catalog_return_loss,
        COUNT(DISTINCT b.c_customer_id) AS unique_customers
    FROM base b
    GROUP BY b.ss_store_sk, b.ss_promo_sk
)
SELECT
    a.ss_store_sk,
    a.ss_promo_sk,
    a.total_sales,
    a.total_profit,
    a.total_store_return_loss,
    a.total_catalog_return_loss,
    a.unique_customers,
    (
        SELECT AVG(sub.total_profit)
        FROM agg sub
        WHERE sub.ss_store_sk = a.ss_store_sk
    ) AS avg_store_profit,
    (
        SELECT COUNT(DISTINCT ss_promo_sk) FROM agg
    ) AS total_promotions
FROM agg a
WHERE a.total_sales > 10000
UNION DISTINCT
SELECT
    a.ss_store_sk,
    a.ss_promo_sk,
    a.total_sales,
    a.total_profit,
    a.total_store_return_loss,
    a.total_catalog_return_loss,
    a.unique_customers,
    (
        SELECT AVG(sub.total_profit)
        FROM agg sub
        WHERE sub.ss_store_sk = a.ss_store_sk
    ) AS avg_store_profit,
    (
        SELECT COUNT(DISTINCT ss_promo_sk) FROM agg
    ) AS total_promotions
FROM agg a
WHERE a.total_store_return_loss > 5000
ORDER BY total_sales DESC
LIMIT 100
