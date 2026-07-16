WITH web_page_site AS (
 SELECT DISTINCT ws.ws_web_page_sk AS web_page_sk, ws.ws_web_site_sk AS web_site_sk
 FROM web_sales ws
),

sales_union AS (
 SELECT ss.ss_store_sk AS store_sk,
        NULL AS entity_id,
        s.s_state AS state,
        d.d_year AS sales_year,
        i.i_category AS category,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity,
        ss.ss_ext_discount_amt AS discount,
        'store' AS channel,
        ss.ss_promo_sk AS promo_sk
 FROM store_sales ss
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 1998 AND 1999

 UNION ALL

 SELECT NULL AS store_sk,
        w.web_site_id AS entity_id,
        NULL AS state,
        d.d_year AS sales_year,
        i.i_category AS category,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity AS quantity,
        ws.ws_ext_discount_amt AS discount,
        'web' AS channel,
        ws.ws_promo_sk AS promo_sk
 FROM web_sales ws
 JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 1998 AND 1999

 UNION ALL

 SELECT NULL AS store_sk,
        cc.cc_call_center_id AS entity_id,
        NULL AS state,
        d.d_year AS sales_year,
        i.i_category AS category,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity,
        cs.cs_ext_discount_amt AS discount,
        'catalog' AS channel,
        cs.cs_promo_sk AS promo_sk
 FROM catalog_sales cs
 JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 1998 AND 1999
),

returns_union AS (
 SELECT sr.sr_store_sk AS store_sk,
        NULL AS entity_id,
        d.d_year AS sales_year,
        i.i_category AS category,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS return_qty,
        'store' AS channel
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN item i ON sr.sr_item_sk = i.i_item_sk

 UNION ALL

 SELECT NULL AS store_sk,
        w.web_site_id AS entity_id,
        d.d_year AS sales_year,
        i.i_category AS category,
        wr.wr_net_loss AS net_loss,
        wr.wr_return_quantity AS return_qty,
        'web' AS channel
 FROM web_returns wr
 JOIN web_page_site wps ON wr.wr_web_page_sk = wps.web_page_sk
 JOIN web_site w ON wps.web_site_sk = w.web_site_sk
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 JOIN item i ON wr.wr_item_sk = i.i_item_sk

 UNION ALL

 SELECT NULL AS store_sk,
        cc.cc_call_center_id AS entity_id,
        d.d_year AS sales_year,
        i.i_category AS category,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_quantity AS return_qty,
        'catalog' AS channel
 FROM catalog_returns cr
 JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 JOIN item i ON cr.cr_item_sk = i.i_item_sk
),

sales_agg AS (
 SELECT
        COALESCE(s.entity_id, CAST(s.store_sk AS VARCHAR)) AS entity_id,
        s.state,
        s.sales_year,
        s.category,
        s.channel,
        sum(s.net_paid) AS total_net_paid,
        sum(s.net_profit) AS total_net_profit,
        sum(s.quantity) AS total_quantity,
        sum(s.discount) AS total_discount
 FROM sales_union s
 GROUP BY
        COALESCE(s.entity_id, CAST(s.store_sk AS VARCHAR)),
        s.state,
        s.sales_year,
        s.category,
        s.channel
),

returns_agg AS (
 SELECT
        COALESCE(r.entity_id, CAST(r.store_sk AS VARCHAR)) AS entity_id,
        r.sales_year,
        r.category,
        r.channel,
        sum(r.net_loss) AS total_net_loss,
        sum(r.return_qty) AS total_return_qty
 FROM returns_union r
 GROUP BY
        COALESCE(r.entity_id, CAST(r.store_sk AS VARCHAR)),
        r.sales_year,
        r.category,
        r.channel
),

combined AS (
 SELECT
        sa.entity_id,
        sa.state,
        sa.sales_year,
        sa.category,
        sa.channel,
        sa.total_net_paid,
        sa.total_net_profit,
        COALESCE(ra.total_net_loss, 0) AS total_net_loss,
        sa.total_quantity,
        sa.total_discount,
        (sa.total_net_profit - COALESCE(ra.total_net_loss, 0)) AS adjusted_net_profit,
        (sa.total_net_paid - COALESCE(ra.total_net_loss, 0)) AS adjusted_net_paid,
        CASE WHEN (sa.total_net_paid - COALESCE(ra.total_net_loss, 0)) = 0 THEN 0
             ELSE (sa.total_net_profit - COALESCE(ra.total_net_loss, 0)) / (sa.total_net_paid - COALESCE(ra.total_net_loss, 0))
        END AS profit_margin
 FROM sales_agg sa
 LEFT JOIN returns_agg ra
   ON sa.entity_id = ra.entity_id
  AND sa.sales_year = ra.sales_year
  AND sa.category = ra.category
  AND sa.channel = ra.channel
)

SELECT
   entity_id,
   state,
   sales_year,
   category,
   channel,
   adjusted_net_paid,
   adjusted_net_profit,
   profit_margin,
   sum(adjusted_net_profit) OVER (PARTITION BY sales_year ORDER BY profit_margin DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_by_year,
   rank() OVER (PARTITION BY sales_year ORDER BY adjusted_net_profit DESC) AS profit_rank
FROM combined
WHERE adjusted_net_paid > 0
ORDER BY sales_year, profit_rank
LIMIT 100
