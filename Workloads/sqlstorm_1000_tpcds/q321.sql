WITH
store_sales_agg AS (
    SELECT
        d.d_year AS year,
        'Store' AS channel_type,
        s.s_store_sk AS channel_id,
        s.s_store_name AS channel_name,
        s.s_state AS channel_location,
        i.i_category,
        i.i_class,
        sum(ss.ss_net_profit) AS sales_profit,
        sum(ss.ss_quantity) AS sales_quantity,
        sum(ss.ss_ext_discount_amt) AS sales_discount,
        sum(coalesce(p.p_cost, 0)) AS promo_cost
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, s.s_store_sk, s.s_store_name, s.s_state, i.i_category, i.i_class
),
store_returns_agg AS (
    SELECT
        d.d_year AS year,
        'Store' AS channel_type,
        s.s_store_sk AS channel_id,
        sum(sr.sr_net_loss) AS returns_loss,
        sum(sr.sr_return_quantity) AS returns_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, s.s_store_sk
),
catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        'Catalog' AS channel_type,
        cc.cc_call_center_sk AS channel_id,
        cc.cc_name AS channel_name,
        cc.cc_state AS channel_location,
        i.i_category,
        i.i_class,
        sum(cs.cs_net_profit) AS sales_profit,
        sum(cs.cs_quantity) AS sales_quantity,
        sum(cs.cs_ext_discount_amt) AS sales_discount,
        sum(coalesce(p.p_cost, 0)) AS promo_cost
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, cc.cc_call_center_sk, cc.cc_name, cc.cc_state, i.i_category, i.i_class
),
catalog_returns_agg AS (
    SELECT
        d.d_year AS year,
        'Catalog' AS channel_type,
        cc.cc_call_center_sk AS channel_id,
        sum(cr.cr_net_loss) AS returns_loss,
        sum(cr.cr_return_quantity) AS returns_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, cc.cc_call_center_sk
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        'Web' AS channel_type,
        wp.wp_web_page_sk AS channel_id,
        wp.wp_url AS channel_name,
        wp.wp_type AS channel_location,
        i.i_category,
        i.i_class,
        sum(ws.ws_net_profit) AS sales_profit,
        sum(ws.ws_quantity) AS sales_quantity,
        sum(ws.ws_ext_discount_amt) AS sales_discount,
        sum(coalesce(p.p_cost, 0)) AS promo_cost
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, wp.wp_web_page_sk, wp.wp_url, wp.wp_type, i.i_category, i.i_class
),
web_returns_agg AS (
    SELECT
        d.d_year AS year,
        'Web' AS channel_type,
        wr.wr_web_page_sk AS channel_id,
        sum(wr.wr_net_loss) AS returns_loss,
        sum(wr.wr_return_quantity) AS returns_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, wr.wr_web_page_sk
),
sales_union AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
returns_union AS (
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM catalog_returns_agg
    UNION ALL
    SELECT * FROM web_returns_agg
),
combined AS (
    SELECT
        s.year,
        s.channel_type,
        s.channel_id,
        s.channel_name,
        s.channel_location,
        s.i_category,
        s.i_class,
        s.sales_profit,
        s.sales_quantity,
        s.sales_discount,
        s.promo_cost,
        coalesce(r.returns_loss,0) AS returns_loss,
        coalesce(r.returns_quantity,0) AS returns_quantity,
        (s.sales_profit - coalesce(r.returns_loss,0)) AS net_profit,
        (s.sales_quantity - coalesce(r.returns_quantity,0)) AS net_quantity,
        (s.sales_discount + coalesce(r.returns_loss,0)) AS total_discount,
        s.promo_cost AS total_promo_cost
    FROM sales_union s
    LEFT JOIN returns_union r
        ON s.year = r.year
       AND s.channel_type = r.channel_type
       AND s.channel_id = r.channel_id
)
SELECT
    c.year,
    c.channel_type,
    c.channel_name,
    c.channel_location,
    c.i_category,
    c.i_class,
    c.net_profit,
    c.net_quantity,
    round(c.net_profit / nullif(c.net_quantity,0),2) AS profit_per_item,
    round(c.total_promo_cost / nullif(c.net_quantity,0),2) AS promo_cost_per_item,
    round(c.total_promo_cost / nullif(s.s_number_employees,0),2) AS promo_cost_per_employee,
    round(c.net_profit / nullif(s.s_number_employees,0),2) AS profit_per_employee,
    row_number() OVER (PARTITION BY c.year, c.channel_type ORDER BY c.net_profit DESC) AS rank_in_year,
    round(100.0 * c.net_profit / sum(c.net_profit) OVER (PARTITION BY c.year),2) AS profit_pct_of_year
FROM combined c
LEFT JOIN store s
    ON c.channel_type = 'Store' AND c.channel_id = s.s_store_sk
WHERE c.net_profit > 0
ORDER BY c.year, c.channel_type, rank_in_year
LIMIT 100
