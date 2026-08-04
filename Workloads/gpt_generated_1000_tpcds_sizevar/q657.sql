WITH sampled_sales AS (
   SELECT cs.cs_item_sk,
          cs.cs_order_number,
          cs.cs_net_paid_inc_tax,
          cs.cs_quantity,
          cs.cs_promo_sk,
          cs.cs_call_center_sk,
          cs.cs_bill_hdemo_sk,
          cs.cs_sold_date_sk
   FROM catalog_sales cs
   TABLESAMPLE BERNOULLI (5)
   WHERE cs.cs_net_paid_inc_tax > 500
),
sales_joined AS (
   SELECT ss.cs_item_sk,
          i.i_item_id,
          i.i_product_name,
          ss.cs_net_paid_inc_tax,
          ss.cs_quantity,
          p.p_promo_name,
          cc.cc_name AS call_center_name
   FROM sampled_sales ss
   JOIN item i ON ss.cs_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON ss.cs_promo_sk = p.p_promo_sk
   LEFT JOIN call_center cc ON ss.cs_call_center_sk = cc.cc_call_center_sk
   WHERE EXISTS (
        SELECT 1
        FROM household_demographics hd
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE hd.hd_demo_sk = ss.cs_bill_hdemo_sk
          AND ib.ib_upper_bound > 150000
   )
),
full_returns AS (
   SELECT sr.sr_item_sk,
          i.i_item_id,
          i.i_product_name,
          sr.sr_return_amt,
          sr.sr_return_quantity,
          r.r_reason_desc
   FROM store_returns sr
   FULL OUTER JOIN item i ON sr.sr_item_sk = i.i_item_sk
   LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE EXISTS (
        SELECT 1
        FROM customer_address ca
        WHERE ca.ca_address_sk = sr.sr_addr_sk
          AND ca.ca_state = 'CA'
   )
),
union_all_data AS (
   SELECT s.cs_item_sk AS item_sk,
          s.i_item_id,
          s.i_product_name,
          s.cs_net_paid_inc_tax AS amount,
          s.cs_quantity AS units,
          s.p_promo_name AS promo,
          s.call_center_name AS source
   FROM sales_joined s
   UNION ALL
   SELECT fr.sr_item_sk AS item_sk,
          fr.i_item_id,
          fr.i_product_name,
          fr.sr_return_amt AS amount,
          fr.sr_return_quantity AS units,
          fr.r_reason_desc AS promo,
          'Return' AS source
   FROM full_returns fr
   WHERE fr.sr_item_sk IS NOT NULL
)
SELECT item_sk,
       i_item_id,
       i_product_name,
       amount,
       units,
       promo,
       source
FROM union_all_data
ORDER BY amount DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
