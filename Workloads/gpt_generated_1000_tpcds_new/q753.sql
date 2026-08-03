WITH filtered_sales AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_item_sk,
       cs.cs_quantity,
       cs.cs_sales_price,
       cs.cs_net_paid,
       cs.cs_order_number,
       cs.cs_promo_sk,
       cs.cs_ship_mode_sk,
       cs.cs_bill_addr_sk,
       cs.cs_bill_cdemo_sk,
       cs.cs_bill_hdemo_sk,
       d.d_year,
       i.i_category,
       i.i_brand,
       p.p_discount_active,
       sm.sm_type,
       ca.ca_state,
       cd.cd_gender,
       hd.hd_buy_potential,
       ARRAY[cs.cs_quantity, CAST(cs.cs_sales_price AS integer)] AS qty_price_arr
   FROM catalog_sales cs
   JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i                    ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm              ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_address ca       ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 2001
     AND i.i_category = 'Sports'
     AND p.p_discount_active = 'Y'
     AND sm.sm_type = 'AIR'
     AND hd.hd_buy_potential = '501-1000'
     AND cs.cs_quantity > 5
),
aggregated AS (
   SELECT
       fs.cs_sold_date_sk,
       fs.cs_item_sk,
       fs.cs_quantity,
       fs.cs_sales_price,
       fs.cs_net_paid,
       fs.cs_order_number,
       s.s_store_name,
       d.d_year,
       r.r_reason_desc,
       wr.wr_return_quantity,
       wr.wr_return_amt,
       ws.web_site_id,
       fs.qty_price_arr
   FROM filtered_sales fs
   LEFT JOIN store_returns sr
          ON sr.sr_item_sk = fs.cs_item_sk
         AND sr.sr_returned_date_sk = fs.cs_sold_date_sk
   LEFT JOIN store s
          ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN reason r
          ON sr.sr_reason_sk = r.r_reason_sk
   LEFT JOIN web_returns wr
          ON wr.wr_item_sk = fs.cs_item_sk
         AND wr.wr_returned_date_sk = fs.cs_sold_date_sk
   LEFT JOIN web_site ws
          ON ws.web_open_date_sk = fs.cs_sold_date_sk
   LEFT JOIN date_dim d
          ON ws.web_open_date_sk = d.d_date_sk
   WHERE fs.cs_order_number NOT IN (
         SELECT sr2.sr_ticket_number
         FROM store_returns sr2
         WHERE sr2.sr_return_quantity > 0
   )
),
store_year_agg AS (
   SELECT
       s_store_name,
       d_year,
       SUM(cs_net_paid)                         AS total_net_paid,
       AVG(cs_sales_price)                      AS avg_sales_price,
       COUNT(DISTINCT cs_order_number)          AS orders_cnt,
       CASE WHEN SUM(cs_net_paid) > 100000 THEN 'HIGH' ELSE 'NORMAL' END AS revenue_category,
       SUM(val)                                 AS total_qty_price_sum
   FROM aggregated
   CROSS JOIN UNNEST(qty_price_arr) AS t(val)
   GROUP BY s_store_name, d_year
),
ranked AS (
   SELECT
       *,
       ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS rn
   FROM store_year_agg
)
SELECT
   s_store_name,
   d_year,
   total_net_paid,
   avg_sales_price,
   orders_cnt,
   revenue_category,
   rn
FROM ranked
WHERE rn <= 5
ORDER BY total_net_paid DESC
OFFSET 10 ROWS FETCH FIRST 100 ROWS ONLY
