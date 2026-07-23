/*
  Goal: Compare total net profit and net paid by income band across store and web sales channels for customers with recent reviews and email promotions, categorizing profit as Positive or Negative.
*/
WITH store_agg AS (
    SELECT
        'store' AS sales_channel,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_net_paid) AS total_net_paid,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Positive' ELSE 'Negative' END AS profit_category
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE c.c_last_review_date > 2452000
      AND p.p_channel_email = 'Y'
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
web_agg AS (
    SELECT
        'web' AS sales_channel,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_net_paid) AS total_net_paid,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Positive' ELSE 'Negative' END AS profit_category
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE c.c_last_review_date > 2452000
      AND p.p_channel_email = 'Y'
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    sales_channel,
    ib_lower_bound,
    ib_upper_bound,
    total_net_profit,
    total_net_paid,
    profit_category
FROM (
    SELECT
        sales_channel,
        ib_lower_bound,
        ib_upper_bound,
        total_net_profit,
        total_net_paid,
        profit_category
    FROM store_agg
    UNION ALL
    SELECT
        sales_channel,
        ib_lower_bound,
        ib_upper_bound,
        total_net_profit,
        total_net_paid,
        profit_category
    FROM web_agg
) combined
ORDER BY total_net_profit DESC, sales_channel
LIMIT 100
