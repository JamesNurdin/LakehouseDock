WITH order_without_returns AS (
    SELECT ws_order_number
    FROM web_sales
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
),
joined_all AS (
    SELECT
        s.s_store_sk           AS s_store_sk,
        s.s_store_name         AS s_store_name,
        s.s_state              AS s_state,
        i.i_item_sk            AS i_item_sk,
        i.i_category           AS i_category,
        i.i_product_name       AS i_product_name,
        d_sold.d_year          AS d_year,
        ws.ws_quantity         AS ws_quantity,
        ws.ws_sales_price      AS ws_sales_price,
        ws.ws_net_profit       AS ws_net_profit,
        cs.cs_quantity         AS cs_quantity,
        cs.cs_net_profit       AS cs_net_profit,
        CASE 
            WHEN ws.ws_net_profit > 1000 THEN 'High'
            WHEN ws.ws_net_profit > 0    THEN 'Medium'
            ELSE 'Low'
        END                     AS profit_category
    FROM web_sales ws
    INNER JOIN order_without_returns owr
        ON ws.ws_order_number = owr.ws_order_number
    /* sold date */
    INNER JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    /* sold time */
    INNER JOIN time_dim t_sold
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    /* item */
    INNER JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    /* web site */
    INNER JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    /* web page */
    INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    /* catalog sales */
    INNER JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_date_sk = d_sold.d_date_sk
    /* store return (must join through store) */
    INNER JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    INNER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    /* reason for store return */
    INNER JOIN reason reason_sr
        ON sr.sr_reason_sk = reason_sr.r_reason_sk
    /* inventory */
    INNER JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
    /* optional web return – left join */
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN reason reason_wr
        ON wr.wr_reason_sk = reason_wr.r_reason_sk
    LEFT JOIN date_dim dr_sr
        ON sr.sr_returned_date_sk = dr_sr.d_date_sk
    LEFT JOIN time_dim tr_sr
        ON sr.sr_return_time_sk = tr_sr.t_time_sk
    LEFT JOIN date_dim dr_wr
        ON wr.wr_returned_date_sk = dr_wr.d_date_sk
    LEFT JOIN time_dim tr_wr
        ON wr.wr_returned_time_sk = tr_wr.t_time_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN date_dim d_open
        ON wsite.web_open_date_sk = d_open.d_date_sk
    LEFT JOIN date_dim d_close
        ON wsite.web_close_date_sk = d_close.d_date_sk
    LEFT JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    LEFT JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d_sold.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_category = 'Electronics'
      AND ws.ws_sales_price > 100
),
agg_sales AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_state,
        i_item_sk,
        i_category,
        i_product_name,
        d_year,
        profit_category,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price * ws_quantity) AS total_sales_amount,
        SUM(ws_net_profit + cs_net_profit) AS total_net_profit
    FROM joined_all
    GROUP BY
        s_store_sk,
        s_store_name,
        s_state,
        i_item_sk,
        i_category,
        i_product_name,
        d_year,
        profit_category
)
SELECT
    s_store_sk,
    s_store_name,
    s_state,
    i_item_sk,
    i_category,
    i_product_name,
    d_year,
    total_quantity_sold,
    total_sales_amount,
    total_net_profit,
    profit_category,
    RANK() OVER (PARTITION BY s_state ORDER BY total_net_profit DESC) AS profit_rank
FROM agg_sales
ORDER BY total_net_profit DESC, profit_rank
LIMIT 100
