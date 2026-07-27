/*
Goal: Analyze the profitability of catalog pages under each promotion for California warehouses in the year 2001, accounting for sales and returns. The query first aggregates sales and return loss per catalog page and promotion (CTE), then summarizes these aggregates per promotion, categorizing pages as profit or loss, and returns the top promotions by net paid amount.
*/
WITH page_promo_sales AS (
    SELECT
        cp.cp_catalog_page_id,
        p.p_promo_id,
        w.w_warehouse_id,
        d_sold.d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_sales_price) AS total_sales_price,
        COUNT(*) AS sales_cnt,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
        CASE
            WHEN SUM(cs.cs_net_paid) - SUM(COALESCE(cr.cr_net_loss, 0)) > 0 THEN 'Profit'
            ELSE 'Loss'
        END AS net_status
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d_sold.d_year = 2001
      AND cp.cp_department = 'Books'
      AND w.w_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND d_sold.d_month_seq BETWEEN 1200 AND 1300
      AND cs.cs_quantity > 1
    GROUP BY cp.cp_catalog_page_id, p.p_promo_id, w.w_warehouse_id, d_sold.d_year
)
SELECT
    p_promo_id,
    COUNT(DISTINCT cp_catalog_page_id) AS page_count,
    SUM(total_net_paid) AS agg_net_paid,
    AVG(total_net_paid) AS avg_net_paid,
    SUM(total_return_loss) AS agg_return_loss,
    SUM(CASE WHEN net_status = 'Profit' THEN 1 ELSE 0 END) AS profit_pages,
    SUM(CASE WHEN net_status = 'Loss' THEN 1 ELSE 0 END) AS loss_pages
FROM page_promo_sales
GROUP BY p_promo_id
HAVING SUM(total_net_paid) > 100000
ORDER BY agg_net_paid DESC
LIMIT 100
