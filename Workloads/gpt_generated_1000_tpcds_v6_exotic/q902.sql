WITH sales_by_brand AS (
    SELECT
        i.i_brand_id,
        i.i_brand,
        i.i_color,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_qty,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(CASE WHEN i.i_color = 'sienna' THEN ws.ws_ext_sales_price ELSE 0 END) AS sienna_sales
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_ext_sales_price > 500
      AND ws.ws_ext_tax < 200
      AND ws.ws_quantity > 1
      AND i.i_brand_id IN (2002002, 6016006)
      AND i.i_color IN ('sienna', 'pink', 'turquoise')
    GROUP BY i.i_brand_id, i.i_brand, i.i_color
    HAVING SUM(ws.ws_ext_sales_price) > 1000
)
SELECT
    sb.i_brand_id,
    sb.i_brand,
    sb.i_color,
    sb.total_sales,
    sb.total_qty,
    sb.avg_sales_price,
    sb.total_profit,
    sb.sienna_sales,
    SUM(sb.total_sales) OVER (ORDER BY sb.total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales,
    RANK() OVER (ORDER BY sb.total_sales DESC) AS sales_rank
FROM sales_by_brand sb
ORDER BY sb.total_sales DESC
LIMIT 100
