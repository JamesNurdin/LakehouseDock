WITH
  base AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_store_sk,
      ss.ss_item_sk,
      ss.ss_cdemo_sk,
      ss.ss_addr_sk,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      ss.ss_sold_date_sk,
      ss.ss_promo_sk
    FROM tpcds.store_sales ss
    WHERE ss.ss_quantity > 0
      AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2450825
  ),
  item_filt AS (
    SELECT *
    FROM tpcds.item i
    WHERE i.i_brand = 'Brand#12'
      AND i.i_rec_start_date <= DATE '2020-01-01'
      AND i.i_rec_end_date >= DATE '2020-12-31'
  ),
  distinct_promo AS (
    SELECT DISTINCT p.p_promo_sk,
                    p.p_promo_name,
                    p.p_discount_active
    FROM tpcds.promotion p
    WHERE p.p_discount_active = 'Y'
  ),
  store_filt AS (
    SELECT *
    FROM tpcds.store s
    WHERE s.s_state = 'CA'
  ),
  cd_filt AS (
    SELECT *
    FROM tpcds.customer_demographics cd
    WHERE cd.cd_gender = 'M'
  ),
  ca_filt AS (
    SELECT *
    FROM tpcds.customer_address ca
    WHERE ca.ca_street_type = 'Road'
  ),
  joined AS (
    SELECT
      s.s_store_name,
      i.i_product_name,
      dp.p_promo_name,
      cd.cd_education_status,
      ca.ca_city,
      b.ss_ticket_number,
      b.ss_ext_sales_price,
      b.ss_quantity,
      b.ss_net_profit,
      r.total_return_inc_tax
    FROM base b
    JOIN item_filt i ON b.ss_item_sk = i.i_item_sk
    JOIN distinct_promo dp ON b.ss_promo_sk = dp.p_promo_sk
    JOIN store_filt s ON b.ss_store_sk = s.s_store_sk
    JOIN cd_filt cd ON b.ss_cdemo_sk = cd.cd_demo_sk
    JOIN ca_filt ca ON b.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN LATERAL (
      SELECT SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax
      FROM tpcds.store_returns sr
      WHERE sr.sr_ticket_number = b.ss_ticket_number
        AND sr.sr_return_amt_inc_tax > 0
    ) r ON TRUE
    WHERE EXISTS (
      SELECT 1
      FROM tpcds.store_returns sr2
      WHERE sr2.sr_store_sk = s.s_store_sk
        AND sr2.sr_refunded_cash > 100
    )
  ),
  ranked AS (
    SELECT
      j.s_store_name,
      j.i_product_name,
      j.p_promo_name,
      j.cd_education_status,
      j.ca_city,
      SUM(j.ss_ext_sales_price) AS total_sales,
      AVG(j.ss_net_profit) AS avg_profit,
      COUNT(DISTINCT j.ss_ticket_number) AS distinct_tickets,
      MAX(j.ss_quantity) AS max_quantity,
      SUM(j.total_return_inc_tax) AS total_return_inc_tax,
      ROW_NUMBER() OVER (PARTITION BY j.s_store_name ORDER BY SUM(j.ss_ext_sales_price) DESC) AS rnk
    FROM joined j
    GROUP BY
      j.s_store_name,
      j.i_product_name,
      j.p_promo_name,
      j.cd_education_status,
      j.ca_city,
      j.total_return_inc_tax
    HAVING SUM(j.ss_ext_sales_price) > 10000
  )
SELECT
  r.s_store_name,
  r.i_product_name,
  r.p_promo_name,
  r.cd_education_status,
  r.ca_city,
  r.total_sales,
  r.avg_profit,
  r.distinct_tickets,
  r.max_quantity,
  r.total_return_inc_tax,
  r.rnk
FROM ranked r
WHERE r.rnk <= 3
ORDER BY r.total_sales DESC
LIMIT 100
