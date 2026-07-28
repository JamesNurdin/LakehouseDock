WITH sales_by_item AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_color,
        SUM(cs.cs_quantity) AS total_qty,
        SUM(cs.cs_net_paid_inc_ship) AS total_paid,
        AVG(cs.cs_ext_list_price) AS avg_list_price
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_class_id IN (13, 9)
      AND i.i_rec_end_date > DATE '2000-01-01'
      AND i.i_color IN ('purple', 'olive')
      AND cs.cs_net_paid_inc_ship > 500
      AND cs.cs_ext_list_price BETWEEN 1000 AND 15000
    GROUP BY i.i_item_sk, i.i_item_id, i.i_brand, i.i_color
)
SELECT
    sb.i_brand,
    sb.i_color,
    SUM(sb.total_qty) AS brand_color_qty,
    SUM(sb.total_paid) AS brand_color_paid,
    AVG(sb.avg_list_price) AS avg_list_price_across_items,
    RANK() OVER (ORDER BY SUM(sb.total_paid) DESC) AS revenue_rank
FROM sales_by_item sb
GROUP BY sb.i_brand, sb.i_color
HAVING SUM(sb.total_paid) > 2000
ORDER BY brand_color_paid DESC
LIMIT 100
