WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        w.web_site_id,
        w.web_name,
        d.d_year,
        SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        COUNT(DISTINCT p.p_promo_sk) AS promo_count,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(p.p_cost) AS avg_promo_cost,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_discount_promo_cnt
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND s.s_country = 'United States'
      AND s.s_division_id = 1
      AND w.web_zip = '93511'
      AND i.inv_quantity_on_hand > 0
      AND p.p_response_target > 5
      AND p.p_purpose = 'Unknown'
    GROUP BY s.s_store_id, s.s_store_name, w.web_site_id, w.web_name, d.d_year
)
SELECT
    agg.s_store_id,
    agg.s_store_name,
    agg.web_site_id,
    agg.web_name,
    agg.d_year,
    agg.total_quantity_on_hand,
    agg.distinct_items,
    agg.promo_count,
    agg.total_promo_cost,
    agg.avg_promo_cost,
    agg.active_discount_promo_cnt,
    ROW_NUMBER() OVER (ORDER BY agg.total_quantity_on_hand DESC) AS row_num,
    (SELECT AVG(p2.p_cost) FROM promotion p2) AS overall_avg_promo_cost
FROM agg
ORDER BY agg.total_quantity_on_hand DESC
LIMIT 100
