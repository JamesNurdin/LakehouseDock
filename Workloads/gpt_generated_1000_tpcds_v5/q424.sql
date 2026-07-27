WITH item_sales AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_store_return,
        SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_web_return,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_return_loss,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss
    FROM item i
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE ws.ws_list_price > 100
        AND ws.ws_coupon_amt > 500
        AND i.i_current_price BETWEEN 20 AND 200
        AND p.p_discount_active = 'Y'
        AND wp.wp_autogen_flag = 'N'
        AND i.i_rec_start_date <= DATE '2002-12-31'
        AND i.i_rec_end_date > DATE '2002-01-01'
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        i.i_brand
    HAVING SUM(ws.ws_ext_sales_price) > 10000
)
SELECT
    i_item_id,
    i_product_name,
    i_brand,
    total_sales,
    total_store_return + total_web_return AS total_returns,
    total_profit - (total_store_return_loss + total_web_return_loss) AS net_profit,
    DENSE_RANK() OVER (PARTITION BY i_brand ORDER BY (total_profit - (total_store_return_loss + total_web_return_loss)) DESC) AS brand_profit_rank
FROM item_sales
ORDER BY net_profit DESC
LIMIT 100
