WITH agg_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cr.cr_net_loss) AS returns_net_loss,
        c.c_customer_sk
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE
        p.p_channel_details LIKE '%discount%'
        AND ib.ib_upper_bound > 50000
        AND i.i_current_price > 100
        AND ss.ss_quantity > 1
        AND cc.cc_gmt_offset > 0
        AND i.i_rec_start_date <= DATE '2022-01-01'
        AND i.i_rec_end_date >= DATE '2022-01-01'
    GROUP BY
        p.p_promo_sk,
        p.p_promo_id,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        c.c_customer_sk
)
SELECT
    agg.p_promo_id,
    SUM(agg.store_net_paid + agg.catalog_net_paid - agg.returns_net_loss) AS total_net_profit,
    COUNT(DISTINCT agg.ib_income_band_sk) AS income_band_count
FROM agg_sales agg
WHERE EXISTS (
    SELECT 1
    FROM web_page wp
    WHERE wp.wp_customer_sk = agg.c_customer_sk
      AND wp.wp_link_count > 5
      AND wp.wp_type = 'Home'
)
GROUP BY agg.p_promo_id
HAVING SUM(agg.store_net_paid + agg.catalog_net_paid - agg.returns_net_loss) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
