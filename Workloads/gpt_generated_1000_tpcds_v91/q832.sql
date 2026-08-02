WITH store_agg AS ( 
    SELECT 
        i.i_item_sk, 
        i.i_product_name, 
        SUM(ss.ss_ext_sales_price) AS store_sales_total, 
        SUM(ss.ss_net_profit) AS store_profit, 
        COUNT(DISTINCT ss.ss_customer_sk) AS store_customers 
    FROM store_sales ss 
    JOIN item i ON ss.ss_item_sk = i.i_item_sk 
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450825 
    GROUP BY i.i_item_sk, i.i_product_name 
), 
web_agg AS ( 
    SELECT 
        i.i_item_sk, 
        i.i_product_name, 
        SUM(ws.ws_ext_sales_price) AS web_sales_total, 
        SUM(ws.ws_net_profit) AS web_profit, 
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customers 
    FROM web_sales ws 
    JOIN item i ON ws.ws_item_sk = i.i_item_sk 
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825 
    GROUP BY i.i_item_sk, i.i_product_name 
), 
common_items AS ( 
    SELECT i_item_sk FROM store_agg 
    INTERSECT 
    SELECT i_item_sk FROM web_agg 
), 
combined AS ( 
    SELECT 
        s.i_item_sk, 
        s.i_product_name, 
        s.store_sales_total, 
        w.web_sales_total, 
        s.store_profit, 
        w.web_profit, 
        CASE 
            WHEN s.store_sales_total > w.web_sales_total THEN 'Store > Web' 
            ELSE 'Web >= Store' 
        END AS sales_comparison, 
        (SELECT AVG(store_sales_total) FROM store_agg) AS avg_store_sales, 
        EXISTS ( 
            SELECT 1 
            FROM web_returns wr 
            WHERE wr.wr_item_sk = s.i_item_sk 
              AND wr.wr_returned_date_sk BETWEEN 2450815 AND 2450825 
        ) AS has_return 
    FROM store_agg s 
    JOIN web_agg w ON s.i_item_sk = w.i_item_sk 
    JOIN common_items ci ON s.i_item_sk = ci.i_item_sk 
) 
SELECT 
    i_item_sk, 
    i_product_name, 
    store_sales_total, 
    web_sales_total, 
    store_profit, 
    web_profit, 
    sales_comparison, 
    avg_store_sales, 
    has_return 
FROM combined 
ORDER BY store_sales_total DESC 
LIMIT 100
