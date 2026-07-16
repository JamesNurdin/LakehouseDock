SELECT
    d_year,
    dim_name,
    i_category,
    profit,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY profit DESC) AS rank
FROM (
    SELECT
        d_year,
        dim_name,
        i_category,
        SUM(net_profit) AS profit
    FROM (
        SELECT
            d.d_year AS d_year,
            s.s_store_name AS dim_name,
            i.i_category AS i_category,
            ss.ss_net_profit AS net_profit
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        UNION ALL
        SELECT
            d.d_year,
            cc.cc_name,
            i.i_category,
            cs.cs_net_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        UNION ALL
        SELECT
            d.d_year,
            w.w_warehouse_name,
            i.i_category,
            ws.ws_net_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
    ) sub
    GROUP BY d_year, dim_name, i_category
) agg
ORDER BY d_year, rank
