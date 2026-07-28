WITH sales_returns_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_net_paid_inc_tax)                     AS total_sales,
        SUM(COALESCE(wr.wr_return_amt, 0))               AS total_returns,
        COUNT(DISTINCT ws.ws_order_number)               AS order_cnt,
        AVG(inv.inv_quantity_on_hand)                    AS avg_inventory,
        (SUM(ws.ws_net_paid_inc_tax) - SUM(COALESCE(wr.wr_return_amt, 0))) AS net_sales
    FROM
        catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN promotion p ON p.p_item_sk = i.i_item_sk
        JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE
        i.i_current_price > 100
        AND p.p_cost > 200
        AND ws.ws_net_paid_inc_tax BETWEEN 100 AND 2000
        AND hd.hd_vehicle_count >= 2
        AND ib.ib_lower_bound >= 50000
        AND wp.wp_type = 'Content'
        AND wsite.web_state = 'CA'
        AND cr.cr_return_quantity > 0
        AND inv.inv_quantity_on_hand < 100
    GROUP BY
        i.i_item_id,
        i.i_product_name
)
SELECT
    sra.i_item_id,
    sra.i_product_name,
    sra.total_sales,
    sra.total_returns,
    sra.net_sales,
    sra.order_cnt,
    sra.avg_inventory
FROM
    sales_returns_agg sra
CROSS JOIN (
    SELECT AVG(net_sales) AS avg_net_sales FROM sales_returns_agg
) avg_tbl
WHERE
    sra.net_sales > avg_tbl.avg_net_sales
ORDER BY
    sra.net_sales DESC
LIMIT 50
