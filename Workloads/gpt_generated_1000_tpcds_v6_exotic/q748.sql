WITH unioned_data AS (
    /* Store sales channel */
    SELECT
        ss.ss_sold_date_sk AS sale_date_sk,
        td.t_hour AS sale_hour,
        i.i_item_id AS item_id,
        i.i_category AS category,
        p.p_promo_id AS promo_id,
        ss.ss_net_paid AS net_amount,
        ss.ss_net_profit AS net_profit,
        'store' AS source
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_quantity > 5
      AND i.i_current_price > 20
      AND td.t_hour BETWEEN 8 AND 20

    UNION ALL

    /* Web sales channel */
    SELECT
        ws.ws_sold_date_sk AS sale_date_sk,
        td.t_hour AS sale_hour,
        i.i_item_id AS item_id,
        i.i_category AS category,
        p.p_promo_id AS promo_id,
        ws.ws_net_paid AS net_amount,
        ws.ws_net_profit AS net_profit,
        'web' AS source
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE ws.ws_quantity > 5
      AND i.i_current_price > 20
      AND td.t_hour BETWEEN 8 AND 20

    UNION ALL

    /* Catalog returns channel */
    SELECT
        cr.cr_returned_date_sk AS sale_date_sk,
        td.t_hour AS sale_hour,
        i.i_item_id AS item_id,
        i.i_category AS category,
        p.p_promo_id AS promo_id,
        -cr.cr_return_amount AS net_amount,
        -cr.cr_net_loss AS net_profit,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_current_price > 20
      AND td.t_hour BETWEEN 8 AND 20
      AND cp.cp_department = 'Electronics'
),
agg AS (
    SELECT
        sale_hour,
        item_id,
        category,
        promo_id,
        source,
        SUM(net_amount) AS total_net,
        SUM(net_profit) AS total_profit
    FROM unioned_data
    GROUP BY sale_hour, item_id, category, promo_id, source
),
avg_total AS (
    SELECT AVG(total_net) AS avg_net FROM agg
)
SELECT
    agg.sale_hour,
    agg.item_id,
    agg.category,
    agg.promo_id,
    agg.total_net,
    agg.total_profit,
    agg.source,
    CASE WHEN agg.total_net > (SELECT avg_net FROM avg_total) THEN 'Above Avg' ELSE 'Below Avg' END AS net_comp,
    RANK() OVER (PARTITION BY agg.sale_hour ORDER BY agg.total_net DESC) AS net_rank
FROM agg
ORDER BY agg.sale_hour, net_rank
LIMIT 100
