SELECT
    year,
    month,
    channel,
    location,
    category,
    SUM(sales_amount) AS total_sales,
    SUM(profit_amount) AS total_profit
FROM (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        'Store' AS channel,
        s.s_store_name AS location,
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_profit) AS profit_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_moy, s.s_store_name, i.i_category

    UNION ALL

    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        'Catalog' AS channel,
        cc.cc_name AS location,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        SUM(cs.cs_net_profit) AS profit_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_moy, cc.cc_name, i.i_category

    UNION ALL

    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        'Web' AS channel,
        w.web_name AS location,
        i.i_category AS category,
        SUM(ws.ws_ext_sales_price) AS sales_amount,
        SUM(ws.ws_net_profit) AS profit_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_moy, w.web_name, i.i_category
) t
GROUP BY year, month, channel, location, category
ORDER BY total_sales DESC
LIMIT 100
