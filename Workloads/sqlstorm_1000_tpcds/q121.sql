SELECT
  state,
  country,
  i_category,
  total_profit,
  total_sales,
  avg_profit,
  state_rank
FROM (
  SELECT
    state,
    country,
    i_category,
    total_profit,
    total_sales,
    avg_profit,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_profit DESC) AS state_rank
  FROM (
    SELECT
      COALESCE(s.s_state, cc.cc_state, w.web_state) AS state,
      COALESCE(s.s_country, cc.cc_country, w.web_country) AS country,
      i.i_category,
      SUM(f.net_profit) AS total_profit,
      SUM(f.sales_amount) AS total_sales,
      AVG(f.net_profit) AS avg_profit
    FROM (
      SELECT
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_item_sk AS item_sk,
        ss.ss_store_sk AS store_sk,
        CAST(NULL AS integer) AS call_center_sk,
        CAST(NULL AS integer) AS web_site_sk,
        ss.ss_sold_date_sk AS sold_date_sk
      FROM store_sales ss
      UNION ALL
      SELECT
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_item_sk,
        CAST(NULL AS integer) AS store_sk,
        cs.cs_call_center_sk AS call_center_sk,
        CAST(NULL AS integer) AS web_site_sk,
        cs.cs_sold_date_sk AS sold_date_sk
      FROM catalog_sales cs
      UNION ALL
      SELECT
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_item_sk,
        CAST(NULL AS integer) AS store_sk,
        CAST(NULL AS integer) AS call_center_sk,
        ws.ws_web_site_sk AS web_site_sk,
        ws.ws_sold_date_sk AS sold_date_sk
      FROM web_sales ws
    ) f
    JOIN date_dim d ON f.sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON f.store_sk = s.s_store_sk
    LEFT JOIN call_center cc ON f.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN web_site w ON f.web_site_sk = w.web_site_sk
    JOIN item i ON f.item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY
      COALESCE(s.s_state, cc.cc_state, w.web_state),
      COALESCE(s.s_country, cc.cc_country, w.web_country),
      i.i_category
  ) agg
) ranked
WHERE state_rank <= 10
ORDER BY state, state_rank
