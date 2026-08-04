WITH
  /* Base sales filtered to 2001, high purchase estimate and CA stores */
  sales_base AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_store_sk,
      ss.ss_cdemo_sk,
      ss.ss_item_sk,
      ss.ss_ticket_number,
      ss.ss_ext_sales_price,
      ss.ss_net_paid,
      ss.ss_ext_tax,
      ss.ss_quantity,
      d.d_year,
      d.d_quarter_name,
      cd.cd_gender,
      cd.cd_marital_status,
      cd.cd_purchase_estimate,
      st.s_store_name,
      st.s_state,
      st.s_tax_percentage,
      st.s_store_sk AS store_key
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    WHERE d.d_year = 2001
      AND cd.cd_purchase_estimate >= 5000
      AND st.s_state = 'CA'
  ),

  /* Base returns filtered to the same year, CA stores and a minimum return amount */
  returns_base AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_store_sk,
      sr.sr_cdemo_sk,
      sr.sr_item_sk,
      sr.sr_ticket_number,
      sr.sr_return_amt,
      sr.sr_fee,
      sr.sr_net_loss,
      d.d_year AS return_year,
      cd.cd_gender AS return_gender,
      st.s_store_sk AS store_key
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    WHERE d.d_year = 2001
      AND sr.sr_return_amt > 100.00
      AND st.s_state = 'CA'
  ),

  /* Build a simple array of store attributes for UNNEST demonstration */
  store_array AS (
    SELECT
      s.s_store_sk,
      ARRAY[ s.s_store_name, s.s_state, CAST(s.s_tax_percentage AS varchar) ] AS attrs
    FROM store s
    WHERE s.s_state = 'CA'
  ),

  unnested_store AS (
    SELECT
      sa.s_store_sk,
      attr AS store_attribute,
      row_number() OVER (PARTITION BY sa.s_store_sk ORDER BY attr) AS attr_seq
    FROM store_array sa
    CROSS JOIN UNNEST(sa.attrs) AS t(attr)
  ),

  /* Aggregate sales per store and quarter */
  sales_agg AS (
    SELECT
      sb.d_year,
      sb.d_quarter_name,
      sb.s_store_name,
      SUM(sb.ss_ext_sales_price) AS total_sales,
      AVG(sb.ss_net_paid) AS avg_net_paid,
      COUNT(*) AS sales_transactions
    FROM sales_base sb
    GROUP BY sb.d_year, sb.d_quarter_name, sb.s_store_name
  ),

  /* Add a lag window to see previous quarter sales for each store */
  sales_window AS (
    SELECT
      *,
      LAG(total_sales) OVER (PARTITION BY s_store_name ORDER BY d_year, d_quarter_name) AS prev_total_sales
    FROM sales_agg
  ),

  /* Aggregate returns per year and gender */
  returns_agg AS (
    SELECT
      rb.return_year,
      rb.return_gender,
      SUM(rb.sr_return_amt) AS total_returns,
      AVG(rb.sr_fee) AS avg_fee,
      COUNT(*) AS return_transactions
    FROM returns_base rb
    GROUP BY rb.return_year, rb.return_gender
  ),

  /* Add a lead window to see next year return total for each gender */
  returns_window AS (
    SELECT
      *,
      LEAD(total_returns) OVER (PARTITION BY return_gender ORDER BY return_year) AS next_total_returns
    FROM returns_agg
  ),

  /* Union the two aggregated result sets (distinct) */
  unioned AS (
    SELECT
      d_year AS period,
      d_quarter_name AS subperiod,
      s_store_name AS entity,
      total_sales AS metric,
      'sales' AS metric_type,
      sales_transactions AS cnt
    FROM sales_window
    UNION DISTINCT
    SELECT
      return_year AS period,
      CAST(return_gender AS varchar) AS subperiod,
      CAST(NULL AS varchar) AS entity,
      total_returns AS metric,
      'returns' AS metric_type,
      return_transactions AS cnt
    FROM returns_window
  ),

  /* Key sets for EXCEPT demonstration: stores with tax > 5% that are not in the <=5% set */
  high_tax AS (
    SELECT s_store_sk FROM store WHERE s_tax_percentage > 5.00
  ),
  low_tax AS (
    SELECT s_store_sk FROM store WHERE s_tax_percentage <= 5.00
  ),
  tax_excluded AS (
    SELECT s_store_sk FROM high_tax
    EXCEPT
    SELECT s_store_sk FROM low_tax
  )

SELECT
  u.period,
  u.subperiod,
  u.entity,
  u.metric,
  u.metric_type,
  u.cnt,
  us.attr_seq,
  us.store_attribute
FROM unioned u
LEFT JOIN store st ON u.entity = st.s_store_name
LEFT JOIN unnested_store us ON st.s_store_sk = us.s_store_sk
WHERE (st.s_store_sk IS NULL OR st.s_store_sk IN (SELECT s_store_sk FROM tax_excluded))
ORDER BY u.period DESC, u.metric DESC
LIMIT 100
