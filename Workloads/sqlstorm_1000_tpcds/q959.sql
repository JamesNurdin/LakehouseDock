WITH unified_sales AS (
   SELECT cs.cs_sold_date_sk AS sold_date_sk,
          cs.cs_item_sk AS item_sk,
          cs.cs_call_center_sk AS channel_sk,
          'call_center' AS channel_type,
          cs.cs_quantity AS quantity,
          cs.cs_net_profit AS net_profit,
          cs.cs_ext_sales_price AS sales_amount
   FROM catalog_sales cs
   UNION ALL
   SELECT ss.ss_sold_date_sk,
          ss.ss_item_sk,
          ss.ss_store_sk,
          'store',
          ss.ss_quantity,
          ss.ss_net_profit,
          ss.ss_ext_sales_price
   FROM store_sales ss
   UNION ALL
   SELECT ws.ws_sold_date_sk,
          ws.ws_item_sk,
          ws.ws_web_page_sk,
          'web',
          ws.ws_quantity,
          ws.ws_net_profit,
          ws.ws_ext_sales_price
   FROM web_sales ws
),
enriched_sales AS (
   SELECT us.sold_date_sk,
          d.d_year,
          d.d_month_seq,
          us.item_sk,
          i.i_item_id,
          i.i_category,
          i.i_brand,
          i.i_class,
          i.i_color,
          us.channel_type,
          CASE 
              WHEN us.channel_type = 'store' THEN s.s_state
              WHEN us.channel_type = 'call_center' THEN cc.cc_state
              WHEN us.channel_type = 'web' THEN wp.wp_type
              ELSE NULL
          END AS channel_detail,
          us.quantity,
          us.sales_amount,
          us.net_profit
   FROM unified_sales us
   JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
   JOIN item i ON us.item_sk = i.i_item_sk
   LEFT JOIN store s ON us.channel_type = 'store' AND us.channel_sk = s.s_store_sk
   LEFT JOIN call_center cc ON us.channel_type = 'call_center' AND us.channel_sk = cc.cc_call_center_sk
   LEFT JOIN web_page wp ON us.channel_type = 'web' AND us.channel_sk = wp.wp_web_page_sk
),
monthly_aggregates AS (
   SELECT item_sk,
          i_item_id,
          i_category,
          i_brand,
          d_year,
          d_month_seq,
          SUM(quantity) AS total_quantity,
          SUM(sales_amount) AS total_sales,
          SUM(net_profit) AS total_profit
   FROM enriched_sales
   GROUP BY item_sk, i_item_id, i_category, i_brand, d_year, d_month_seq
),
moving_avg AS (
   SELECT ma.*,
          AVG(total_profit) OVER (PARTITION BY item_sk ORDER BY d_year, d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS profit_3month_mavg
   FROM monthly_aggregates ma
),
ranked_items AS (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY profit_3month_mavg DESC) AS rank_year
   FROM moving_avg
),
final AS (
   SELECT d_year,
          i_item_id,
          i_category,
          i_brand,
          d_month_seq,
          total_quantity,
          total_sales,
          total_profit,
          profit_3month_mavg,
          rank_year
   FROM ranked_items
   WHERE rank_year <= 10
)
SELECT *
FROM final
ORDER BY d_year, profit_3month_mavg DESC
