WITH sales_base AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_catalog_page_sk,
    cs.cs_promo_sk,
    cs.cs_bill_hdemo_sk,
    cs.cs_item_sk,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_paid,
    cp.cp_department,
    p.p_promo_name,
    d.d_year,
    d.d_month_seq,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    hd.hd_dep_count,
    hd.hd_vehicle_count
  FROM catalog_sales cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE cp.cp_department = 'Electronics'
    AND p.p_discount_active = 'Y'
    AND d.d_year = 2000
    AND d.d_month_seq BETWEEN 1200 AND 1211
    AND hd.hd_buy_potential = '1001-5000'
    AND hd.hd_vehicle_count >= 1
)
SELECT
  sb.d_year,
  sb.cp_department,
  sb.p_promo_name,
  SUM(sb.cs_ext_sales_price) AS total_sales,
  AVG(sb.cs_quantity) AS avg_quantity,
  COUNT(DISTINCT sb.cs_order_number) AS unique_orders,
  SUM(cr.cr_return_amount) AS total_catalog_return_amount,
  SUM(sr.sr_return_amt) AS total_store_return_amt,
  MIN(cr.cr_return_quantity) AS min_return_qty,
  MAX(sr.sr_return_quantity) AS max_store_return_qty
FROM sales_base sb
JOIN catalog_returns cr
  ON cr.cr_order_number = sb.cs_order_number
  AND cr.cr_item_sk = sb.cs_item_sk
JOIN store_returns sr
  ON sr.sr_returned_date_sk = sb.cs_sold_date_sk
  AND sr.sr_hdemo_sk = sb.cs_bill_hdemo_sk
WHERE EXISTS (
    SELECT 1
    FROM reason r
    WHERE r.r_reason_sk = cr.cr_reason_sk
      AND r.r_reason_desc LIKE '%defect%'
)
  AND sr.sr_store_credit > 10
  AND cr.cr_fee BETWEEN 0 AND 50
  AND sb.hd_dep_count = 2
  AND sb.hd_income_band_sk = 3
GROUP BY
  sb.d_year,
  sb.cp_department,
  sb.p_promo_name
HAVING SUM(sb.cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
