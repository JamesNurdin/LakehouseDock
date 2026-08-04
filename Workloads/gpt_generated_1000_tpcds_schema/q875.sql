WITH
  joined AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_ship_date_sk,
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cs.cs_net_paid,
      cs.cs_net_profit,
      d.d_date,
      d.d_year,
      d.d_quarter_seq,
      d.d_holiday,
      s.s_store_id,
      s.s_state,
      s.s_company_name
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND d.d_holiday = 'N'
      AND s.s_state = 'CA'
      AND cs.cs_ext_sales_price > 100
  ),
  sub_a AS (
    SELECT DISTINCT s_store_id, d_year
    FROM joined
    WHERE cs_net_profit > 0
  ),
  sub_b AS (
    SELECT DISTINCT s_store_id, d_year
    FROM joined
    WHERE cs_quantity >= 10
  ),
  intersect_ab AS (
    SELECT s_store_id, d_year FROM sub_a
    INTERSECT
    SELECT s_store_id, d_year FROM sub_b
  ),
  agg_union AS (
    SELECT s_store_id, d_year AS period, SUM(cs_ext_sales_price) AS total_sales
    FROM joined
    GROUP BY s_store_id, d_year
    UNION
    SELECT s_store_id, d_quarter_seq AS period, SUM(cs_ext_sales_price) AS total_sales
    FROM joined
    GROUP BY s_store_id, d_quarter_seq
  ),
  cube_agg AS (
    SELECT
      s_store_id,
      d_year,
      d_quarter_seq,
      SUM(cs_ext_sales_price) AS sum_sales,
      SUM(cs_net_profit) AS sum_profit
    FROM joined
    GROUP BY CUBE (s_store_id, d_year, d_quarter_seq)
  ),
  final AS (
    SELECT
      ca.s_store_id,
      ca.d_year,
      ca.d_quarter_seq,
      ca.sum_sales,
      ca.sum_profit,
      ROW_NUMBER() OVER (PARTITION BY ca.s_store_id ORDER BY ca.sum_sales DESC) AS rn_store,
      LAG(ca.sum_sales) OVER (PARTITION BY ca.s_store_id ORDER BY ca.d_year, ca.d_quarter_seq) AS lag_sum_sales,
      SUM(ca.sum_sales) OVER (ORDER BY ca.d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales
    FROM cube_agg ca
    JOIN intersect_ab ia
      ON ca.s_store_id = ia.s_store_id
     AND ca.d_year = ia.d_year
    WHERE ca.sum_sales > 500
      AND ca.sum_profit > 100
  )
SELECT *
FROM final
WHERE rn_store <= 5
ORDER BY sum_sales DESC
LIMIT 100
