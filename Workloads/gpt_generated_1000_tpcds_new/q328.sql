WITH union_a AS (
   SELECT
       s.s_state AS state,
       CASE WHEN p.p_channel_email = 'Y' THEN 'Email' ELSE 'NoEmail' END AS promo_type,
       SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
       SUM(ws.ws_ext_sales_price) AS web_sales_amount,
       SUM(sr.sr_net_loss) AS total_return_loss,
       COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
       COUNT(DISTINCT ws.ws_order_number) AS web_orders
   FROM catalog_sales cs
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN store_returns sr ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk AND ws.ws_promo_sk = p.p_promo_sk
   WHERE hd.hd_income_band_sk = 5
     AND p.p_channel_email = 'Y'
     AND s.s_state = 'TX'
     AND cs.cs_quantity > 2
     AND s.s_rec_start_date >= DATE '2001-01-01'
   GROUP BY s.s_state,
            CASE WHEN p.p_channel_email = 'Y' THEN 'Email' ELSE 'NoEmail' END
   UNION
   SELECT
       s.s_state AS state,
       CASE WHEN p.p_channel_email = 'Y' THEN 'Email' ELSE 'NoEmail' END AS promo_type,
       SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
       SUM(ws.ws_ext_sales_price) AS web_sales_amount,
       SUM(sr.sr_net_loss) AS total_return_loss,
       COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
       COUNT(DISTINCT ws.ws_order_number) AS web_orders
   FROM catalog_sales cs
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN store_returns sr ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk AND ws.ws_promo_sk = p.p_promo_sk
   WHERE hd.hd_income_band_sk = 6
     AND p.p_channel_dmail = 'Y'
     AND s.s_state = 'CA'
     AND ws.ws_ext_ship_cost < 500
     AND s.s_rec_start_date >= DATE '2002-01-01'
   GROUP BY s.s_state,
            CASE WHEN p.p_channel_email = 'Y' THEN 'Email' ELSE 'NoEmail' END
),
union_b AS (
   SELECT
       s.s_state AS state,
       CASE WHEN p.p_channel_email = 'Y' THEN 'Email' ELSE 'NoEmail' END AS promo_type,
       SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
       SUM(ws.ws_ext_sales_price) AS web_sales_amount,
       SUM(sr.sr_net_loss) AS total_return_loss,
       COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
       COUNT(DISTINCT ws.ws_order_number) AS web_orders
   FROM catalog_sales cs
   JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN store_returns sr ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN web_sales ws ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk AND ws.ws_promo_sk = p.p_promo_sk
   WHERE sr.sr_return_ship_cost > 100
     AND cs.cs_quantity BETWEEN 1 AND 5
     AND p.p_channel_press = 'N'
     AND s.s_state = 'TX'
   GROUP BY s.s_state,
            CASE WHEN p.p_channel_email = 'Y' THEN 'Email' ELSE 'NoEmail' END
   UNION
   SELECT
       s.s_state AS state,
       CASE WHEN p.p_channel_email = 'Y' THEN 'Email' ELSE 'NoEmail' END AS promo_type,
       SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
       SUM(ws.ws_ext_sales_price) AS web_sales_amount,
       SUM(sr.sr_net_loss) AS total_return_loss,
       COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
       COUNT(DISTINCT ws.ws_order_number) AS web_orders
   FROM catalog_sales cs
   JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN store_returns sr ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN web_sales ws ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk AND ws.ws_promo_sk = p.p_promo_sk
   WHERE ws.ws_ext_ship_cost > 200
     AND sr.sr_return_tax > 150
     AND p.p_channel_dmail = 'N'
     AND s.s_state = 'CA'
   GROUP BY s.s_state,
            CASE WHEN p.p_channel_email = 'Y' THEN 'Email' ELSE 'NoEmail' END
)
SELECT
   state,
   promo_type,
   catalog_sales_amount,
   web_sales_amount,
   total_return_loss,
   catalog_orders,
   web_orders
FROM union_a
INTERSECT
SELECT
   state,
   promo_type,
   catalog_sales_amount,
   web_sales_amount,
   total_return_loss,
   catalog_orders,
   web_orders
FROM union_b
ORDER BY state, promo_type
LIMIT 100
