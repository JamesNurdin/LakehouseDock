WITH unified_sales AS (
   SELECT cs.cs_sold_date_sk AS date_sk,
          cs.cs_item_sk AS item_sk,
          cs.cs_ext_sales_price AS sales,
          cs.cs_net_profit AS profit,
          cs.cs_ext_discount_amt AS discount,
          cs.cs_ext_tax AS tax,
          'catalog' AS channel,
          cs.cs_call_center_sk AS call_center_sk,
          cs.cs_catalog_page_sk AS catalog_page_sk,
          cs.cs_promo_sk AS promo_sk,
          ca.ca_state AS state
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   UNION ALL
   SELECT ss.ss_sold_date_sk AS date_sk,
          ss.ss_item_sk AS item_sk,
          ss.ss_ext_sales_price AS sales,
          ss.ss_net_profit AS profit,
          ss.ss_ext_discount_amt AS discount,
          ss.ss_ext_tax AS tax,
          'store' AS channel,
          NULL AS call_center_sk,
          NULL AS catalog_page_sk,
          ss.ss_promo_sk AS promo_sk,
          s.s_state AS state
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   UNION ALL
   SELECT ws.ws_sold_date_sk AS date_sk,
          ws.ws_item_sk AS item_sk,
          ws.ws_ext_sales_price AS sales,
          ws.ws_net_profit AS profit,
          ws.ws_ext_discount_amt AS discount,
          ws.ws_ext_tax AS tax,
          'web' AS channel,
          NULL AS call_center_sk,
          NULL AS catalog_page_sk,
          ws.ws_promo_sk AS promo_sk,
          ca2.ca_state AS state
   FROM web_sales ws
   JOIN customer_address ca2 ON ws.ws_bill_addr_sk = ca2.ca_address_sk
),
joined_sales AS (
   SELECT
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        us.state,
        us.channel,
        us.sales,
        us.profit,
        us.discount,
        us.tax,
        us.promo_sk
   FROM unified_sales us
   JOIN date_dim d ON us.date_sk = d.d_date_sk
   JOIN item i ON us.item_sk = i.i_item_sk
),
agg_sales AS (
   SELECT
        d_year,
        d_quarter_seq,
        i_category,
        state,
        SUM(sales) AS total_sales,
        SUM(profit) AS total_profit,
        SUM(discount) AS total_discount,
        SUM(tax) AS total_tax,
        COUNT(*) AS txn_count,
        SUM(CASE WHEN promo_sk IS NOT NULL THEN 1 ELSE 0 END) AS promo_txn_cnt,
        SUM(CASE WHEN promo_sk IS NOT NULL THEN sales ELSE 0 END) AS promo_sales,
        SUM(CASE WHEN promo_sk IS NOT NULL THEN discount ELSE 0 END) AS promo_discount
   FROM joined_sales
   GROUP BY d_year, d_quarter_seq, i_category, state
),
promo_category_stats AS (
   SELECT
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        COUNT(*) AS promo_txn_cnt,
        SUM(us.sales) AS promo_sales,
        SUM(us.discount) AS promo_discount,
        SUM(us.discount) / NULLIF(SUM(us.sales), 0) AS promo_discount_rate
   FROM unified_sales us
   JOIN date_dim d ON us.date_sk = d.d_date_sk
   JOIN item i ON us.item_sk = i.i_item_sk
   WHERE us.promo_sk IS NOT NULL
   GROUP BY d.d_year, d.d_quarter_seq, i.i_category
)
SELECT
    a.d_year,
    a.d_quarter_seq,
    a.i_category,
    a.state,
    a.total_sales,
    a.total_profit,
    a.total_discount,
    a.total_tax,
    a.txn_count,
    a.total_profit / NULLIF(a.total_sales, 0) AS profit_margin,
    a.total_profit / NULLIF(a.txn_count, 0) AS avg_profit_per_txn,
    COALESCE(p.promo_txn_cnt, 0) AS promo_txn_cnt,
    COALESCE(p.promo_sales, 0) AS promo_sales,
    COALESCE(p.promo_discount, 0) AS promo_discount,
    CASE WHEN COALESCE(p.promo_sales, 0) = 0 THEN 0 ELSE p.promo_discount / p.promo_sales END AS promo_discount_rate,
    RANK() OVER (PARTITION BY a.d_year, a.d_quarter_seq ORDER BY a.total_sales DESC) AS sales_rank,
    NTILE(5) OVER (PARTITION BY a.d_year, a.d_quarter_seq ORDER BY a.total_sales DESC) AS sales_quintile
FROM agg_sales a
LEFT JOIN promo_category_stats p
   ON a.d_year = p.d_year
   AND a.d_quarter_seq = p.d_quarter_seq
   AND a.i_category = p.i_category
ORDER BY a.d_year, a.d_quarter_seq, a.total_sales DESC
