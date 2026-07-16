SELECT
    d_year,
    state,
    total_net_profit,
    total_net_paid,
    total_ext_sales,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        d_year,
        state,
        SUM(net_profit) AS total_net_profit,
        SUM(net_paid) AS total_net_paid,
        SUM(ext_sales) AS total_ext_sales
    FROM (
        SELECT
            d.d_year,
            ca.ca_state AS state,
            cs.cs_net_profit AS net_profit,
            cs.cs_net_paid AS net_paid,
            cs.cs_ext_sales_price AS ext_sales
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
        UNION ALL
        SELECT
            d.d_year,
            ca.ca_state AS state,
            ws.ws_net_profit,
            ws.ws_net_paid,
            ws.ws_ext_sales_price
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
        UNION ALL
        SELECT
            d.d_year,
            s.s_state AS state,
            ss.ss_net_profit,
            ss.ss_net_paid,
            ss.ss_ext_sales_price
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
    ) sales
    GROUP BY d_year, state
) agg
ORDER BY d_year, profit_rank
