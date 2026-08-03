WITH cat_data AS (
   SELECT
     cs.cs_item_sk                AS item_sk,
     i.i_brand,
     i.i_category,
     cs.cs_quantity               AS quantity,
     cs.cs_sales_price            AS amount,
     cc.cc_name,
     cp.cp_department,
     c.c_last_name,
     hd.hd_income_band_sk,
     cd.cd_gender
   FROM catalog_sales cs
   JOIN item i               ON cs.cs_item_sk = i.i_item_sk
   JOIN call_center cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer c           ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN catalog_returns cr   ON cr.cr_order_number = cs.cs_order_number
                                  AND cr.cr_item_sk = cs.cs_item_sk
   LEFT JOIN reason r             ON cr.cr_reason_sk = r.r_reason_sk
),
store_data AS (
   SELECT
     ss.ss_item_sk                AS item_sk,
     i2.i_brand,
     i2.i_category,
     ss.ss_quantity               AS quantity,
     ss.ss_net_paid               AS amount,
     s.s_state,
     cd2.cd_gender,
     hd2.hd_income_band_sk,
     r2.r_reason_desc
   FROM store_sales ss
   JOIN item i2               ON ss.ss_item_sk = i2.i_item_sk
   JOIN store s               ON ss.ss_store_sk = s.s_store_sk
   JOIN customer c2          ON ss.ss_customer_sk = c2.c_customer_sk
   JOIN customer_demographics cd2 ON ss.ss_cdemo_sk = cd2.cd_demo_sk
   JOIN household_demographics hd2 ON ss.ss_hdemo_sk = hd2.hd_demo_sk
   LEFT JOIN store_returns sr     ON sr.sr_ticket_number = ss.ss_ticket_number
   LEFT JOIN reason r2            ON sr.sr_reason_sk = r2.r_reason_sk
)
SELECT
  item_sk,
  i_brand,
  i_category,
  quantity,
  amount,
  CASE WHEN amount > (
         SELECT AVG(cs_sales_price)
         FROM catalog_sales
         WHERE cs_quantity > 1
       ) THEN 'High' ELSE 'Low' END AS price_category,
  ROW_NUMBER() OVER (ORDER BY amount DESC) AS rn
FROM (
   SELECT
     cd.item_sk,
     cd.i_brand,
     cd.i_category,
     cd.quantity,
     cd.amount
   FROM cat_data cd
   WHERE cd.cc_name = 'Call Center 1'
     AND cd.cp_department = 'Electronics'
     AND cd.c_last_name = 'Wilder'
     AND cd.hd_income_band_sk IN (5, 11)
     AND cd.amount > 50
     AND cd.quantity >= 2

   EXCEPT

   SELECT
     sd.item_sk,
     sd.i_brand,
     sd.i_category,
     sd.quantity,
     sd.amount
   FROM store_data sd
   WHERE sd.s_state = 'CA'
     AND sd.i_brand = 'BrandX'
     AND sd.cd_gender = 'M'
     AND sd.hd_income_band_sk = 6
     AND sd.amount > 100
     AND sd.quantity >= 3
) AS diff
ORDER BY price_category DESC, rn
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
