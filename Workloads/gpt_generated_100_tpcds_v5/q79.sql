WITH sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ds.d_date_sk,
        hd.hd_buy_potential
    FROM store s
    JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(s.s_store_name, '^.*Super.*$')
      AND hd.hd_buy_potential LIKE '5001-%'
)
SELECT
    s.s_store_name,
    substring(s.s_store_name, 1, 5) AS store_prefix,
    s.s_city,
    COUNT(DISTINCT sa.ss_ticket_number) AS total_transactions,
    SUM(sa.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_net_loss,
    SUM(CASE WHEN sr.sr_returned_date_sk = d.d_date_sk THEN 1 ELSE 0 END) AS returns_on_sale_date,
    regexp_extract(wp.wp_url, '(https?://[^/]+)') AS url_domain
FROM store s
JOIN sales sa ON sa.s_store_sk = s.s_store_sk
JOIN date_dim d ON sa.d_date_sk = d.d_date_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = sa.ss_ticket_number
   AND sr.sr_item_sk = sa.ss_item_sk
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
WHERE wp.wp_url LIKE concat('%', s.s_city, '%')
  AND EXISTS (
        SELECT 1
        FROM call_center cc
        WHERE cc.cc_manager LIKE concat('%', s.s_city, '%')
          AND cc.cc_closed_date_sk = d.d_date_sk
    )
GROUP BY
    s.s_store_name,
    substring(s.s_store_name, 1, 5),
    s.s_city,
    wp.wp_url,
    regexp_extract(wp.wp_url, '(https?://[^/]+)')
HAVING SUM(sa.ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
