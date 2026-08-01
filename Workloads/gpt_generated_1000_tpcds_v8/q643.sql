WITH catalog_data AS (
   SELECT
       cs.cs_order_number AS order_key,
       cs.cs_net_paid,
       cs.cs_sold_date_sk,
       c.c_customer_sk,
       cd.cd_gender,
       hd.hd_income_band_sk,
       ib.ib_lower_bound,
       i.i_item_id,
       p.p_promo_id,
       cc.cc_call_center_id
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2455000
     AND i.i_brand = 'Brand#23'
     AND cc.cc_state = 'CA'
     AND p.p_discount_active = 'Y'
     AND cd.cd_credit_rating = 'Excellent'
),
store_web_data AS (
   SELECT
       COALESCE(ss.ss_ticket_number, ws.ws_order_number) AS order_key,
       ss.ss_net_paid,
       ws.ws_net_paid,
       COALESCE(ss.ss_sold_date_sk, ws.ws_sold_date_sk) AS sold_date_sk,
       s.s_store_sk,
       c.c_customer_sk,
       cd.cd_gender,
       hd.hd_income_band_sk,
       ib.ib_lower_bound,
       i.i_item_id,
       p.p_promo_id,
       sr.sr_return_amt_inc_tax,
       r.r_reason_id
   FROM store_sales ss
   FULL OUTER JOIN web_sales ws
       ON ss.ss_item_sk = ws.ws_item_sk
   LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
   LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   LEFT JOIN item i ON (ss.ss_item_sk = i.i_item_sk OR ws.ws_item_sk = i.i_item_sk)
   LEFT JOIN promotion p ON (ss.ss_promo_sk = p.p_promo_sk OR ws.ws_promo_sk = p.p_promo_sk)
   LEFT JOIN customer c ON (ss.ss_customer_sk = c.c_customer_sk OR ws.ws_bill_customer_sk = c.c_customer_sk)
   LEFT JOIN customer_demographics cd ON (ss.ss_cdemo_sk = cd.cd_demo_sk OR ws.ws_bill_cdemo_sk = cd.cd_demo_sk)
   LEFT JOIN household_demographics hd ON (ss.ss_hdemo_sk = hd.hd_demo_sk OR ws.ws_bill_hdemo_sk = hd.hd_demo_sk)
   LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE (ss.ss_quantity > 1 OR ws.ws_quantity > 2)
     AND (s.s_state = 'TX' OR s.s_state IS NULL)
     AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
     AND (i.i_color = 'Red' OR i.i_color IS NULL)
     AND (c.c_birth_year BETWEEN 1960 AND 1970 OR c.c_birth_year IS NULL)
),
filtered_catalog AS (
   SELECT *
   FROM catalog_data
   WHERE order_key NOT IN (
        SELECT ws_order_number
        FROM web_sales
        WHERE ws_order_number IS NOT NULL
   )
),
key_diff AS (
   SELECT order_key FROM catalog_data
   EXCEPT
   SELECT order_key FROM store_web_data
),
combined AS (
   SELECT order_key,
          cs_net_paid AS net_paid,
          cs_sold_date_sk AS sold_date_sk,
          c_customer_sk,
          cd_gender,
          ib_lower_bound,
          i_item_id,
          p_promo_id
   FROM filtered_catalog
   UNION ALL
   SELECT order_key,
          COALESCE(ss_net_paid, ws_net_paid) AS net_paid,
          sold_date_sk,
          c_customer_sk,
          cd_gender,
          ib_lower_bound,
          i_item_id,
          p_promo_id
   FROM store_web_data
)
SELECT
   order_key,
   net_paid,
   sold_date_sk,
   c_customer_sk,
   cd_gender,
   ib_lower_bound,
   i_item_id,
   p_promo_id,
   SUM(net_paid) OVER (PARTITION BY c_customer_sk ORDER BY sold_date_sk
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid,
   RANK() OVER (PARTITION BY cd_gender ORDER BY net_paid DESC) AS gender_rank
FROM combined
WHERE order_key IN (SELECT order_key FROM key_diff)
ORDER BY net_paid DESC
OFFSET 10
LIMIT 100
