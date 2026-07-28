WITH item_sales AS (
   SELECT
       d.d_date AS transaction_date,
       s.s_store_id,
       s.s_state,
       i.i_item_id,
       i.i_brand,
       ss.ss_net_paid,
       ss.ss_net_profit,
       CASE WHEN ss.ss_net_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag,
       ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_paid DESC) AS rn_store_sales,
       (
           SELECT SUM(ss2.ss_net_profit)
           FROM store_sales ss2
           WHERE ss2.ss_item_sk = ss.ss_item_sk
       ) AS total_item_profit
   FROM date_dim d
   JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                              AND sr.sr_item_sk = ss.ss_item_sk
   LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                                 AND cr.cr_item_sk = ss.ss_item_sk
   LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                           AND ws.ws_item_sk = ss.ss_item_sk
   LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
   LEFT JOIN reason r1 ON sr.sr_reason_sk = r1.r_reason_sk
   LEFT JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
   LEFT JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
   WHERE d.d_year = 2001
     AND i.i_brand = 'BrandX'
     AND s.s_state = 'CA'
)
SELECT
    transaction_date,
    s_store_id,
    s_state,
    i_item_id,
    i_brand,
    ss_net_paid,
    ss_net_profit,
    profit_flag,
    rn_store_sales,
    total_item_profit
FROM item_sales
WHERE rn_store_sales <= 5
ORDER BY transaction_date DESC, total_item_profit DESC
LIMIT 100
