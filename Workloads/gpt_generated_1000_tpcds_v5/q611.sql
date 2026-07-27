WITH sales_demo AS (
    SELECT
        ss.ss_net_paid,
        ss.ss_promo_sk,
        ss.ss_addr_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    city,
    state,
    promo_name,
    lower_bound,
    upper_bound,
    total_net_paid,
    sales_cnt
FROM (
    SELECT
        ca.ca_city AS city,
        ca.ca_state AS state,
        p.p_promo_name AS promo_name,
        sd.ib_lower_bound AS lower_bound,
        sd.ib_upper_bound AS upper_bound,
        SUM(sd.ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM sales_demo sd
    JOIN promotion p ON sd.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON sd.ss_addr_sk = ca.ca_address_sk
    WHERE p.p_channel_email = 'Y'
      AND sd.ss_net_paid > 1000
    GROUP BY ca.ca_city, ca.ca_state, p.p_promo_name, sd.ib_lower_bound, sd.ib_upper_bound

    UNION ALL

    SELECT
        ca.ca_city,
        ca.ca_state,
        p.p_promo_name,
        sd.ib_lower_bound,
        sd.ib_upper_bound,
        SUM(sd.ss_net_paid),
        COUNT(*)
    FROM sales_demo sd
    JOIN promotion p ON sd.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON sd.ss_addr_sk = ca.ca_address_sk
    WHERE p.p_channel_catalog = 'Y'
      AND sd.ss_net_paid > 500
    GROUP BY ca.ca_city, ca.ca_state, p.p_promo_name, sd.ib_lower_bound, sd.ib_upper_bound
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
