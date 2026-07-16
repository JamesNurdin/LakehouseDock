WITH sales_agg AS (
    SELECT
        p.p_promo_id,
        d_sold.d_year AS sales_year,
        w.w_warehouse_name,
        COUNT(*) AS sales_cnt,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d_sold.d_year BETWEEN 2000 AND 2002
    GROUP BY p.p_promo_id, d_sold.d_year, w.w_warehouse_name
),
returns_agg AS (
    SELECT
        p.p_promo_id,
        d_return.d_year AS return_year,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    WHERE d_return.d_year BETWEEN 2000 AND 2002
    GROUP BY p.p_promo_id, d_return.d_year
)
SELECT
    s.p_promo_id,
    s.sales_year,
    s.w_warehouse_name,
    s.sales_cnt,
    s.total_quantity,
    s.total_sales_amount,
    s.total_discount_amount,
    s.total_net_profit,
    s.distinct_pages,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(r.return_cnt, 0) AS return_cnt,
    s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_margin
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.p_promo_id = r.p_promo_id
    AND s.sales_year = r.return_year
ORDER BY s.total_net_profit DESC
LIMIT 100
