WITH
    cat_agg AS (
        SELECT
            cs.cs_catalog_page_sk AS page_sk,
            cs.cs_warehouse_sk AS warehouse_sk,
            cs.cs_sold_date_sk AS sold_date_sk,
            cs.cs_bill_hdemo_sk AS hd_demo_sk,
            hd.hd_buy_potential AS hd_buy_potential,
            SUM(cs.cs_net_profit) AS net_profit,
            SUM(cs.cs_quantity) AS total_quantity
        FROM catalog_sales cs
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        WHERE cs.cs_quantity > 0
          AND cs.cs_net_profit > 0
          AND cs.cs_list_price > 500
          AND cs.cs_ext_discount_amt < 5000
          AND cs.cs_sold_date_sk BETWEEN 2451085 AND 2451453
        GROUP BY cs.cs_catalog_page_sk,
                 cs.cs_warehouse_sk,
                 cs.cs_sold_date_sk,
                 cs.cs_bill_hdemo_sk,
                 hd.hd_buy_potential
    ),
    web_agg AS (
        SELECT
            NULL AS page_sk,
            ws.ws_warehouse_sk AS warehouse_sk,
            ws.ws_sold_date_sk AS sold_date_sk,
            ws.ws_bill_hdemo_sk AS hd_demo_sk,
            hd2.hd_buy_potential AS hd_buy_potential,
            SUM(ws.ws_net_profit) AS net_profit,
            SUM(ws.ws_quantity) AS total_quantity
        FROM web_sales ws
        JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
        WHERE ws.ws_quantity > 0
          AND ws.ws_net_profit > 0
          AND ws.ws_list_price > 500
          AND ws.ws_ext_discount_amt < 5000
          AND ws.ws_sold_date_sk BETWEEN 2451085 AND 2451453
        GROUP BY ws.ws_warehouse_sk,
                 ws.ws_sold_date_sk,
                 ws.ws_bill_hdemo_sk,
                 hd2.hd_buy_potential
    ),
    sales_union AS (
        SELECT
            page_sk,
            warehouse_sk,
            sold_date_sk,
            hd_demo_sk,
            hd_buy_potential,
            net_profit,
            total_quantity,
            'catalog' AS source
        FROM cat_agg
        UNION ALL
        SELECT
            page_sk,
            warehouse_sk,
            sold_date_sk,
            hd_demo_sk,
            hd_buy_potential,
            net_profit,
            total_quantity,
            'web' AS source
        FROM web_agg
    ),
    joined AS (
        SELECT
            su.source,
            su.sold_date_sk,
            d.d_year,
            d.d_month_seq,
            cp.cp_department,
            su.hd_buy_potential,
            w.w_warehouse_name,
            su.net_profit,
            su.total_quantity,
            CASE
                WHEN su.net_profit > 10000 THEN 'High'
                WHEN su.net_profit > 0 THEN 'Medium'
                ELSE 'Low'
            END AS profit_category
        FROM sales_union su
        LEFT JOIN catalog_page cp ON su.page_sk = cp.cp_catalog_page_sk
        LEFT JOIN warehouse w ON su.warehouse_sk = w.w_warehouse_sk
        LEFT JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
        WHERE d.d_year = 1999
          AND w.w_gmt_offset = (SELECT MAX(w_gmt_offset) FROM warehouse)
          AND su.hd_buy_potential = 'High'
          AND d.d_month_seq >= 1200
    ),
    agg_final AS (
        SELECT
            source,
            d_year,
            d_month_seq,
            profit_category,
            SUM(net_profit) AS total_net_profit,
            SUM(total_quantity) AS total_quantity,
            COUNT(*) AS row_cnt
        FROM joined
        GROUP BY source,
                 d_year,
                 d_month_seq,
                 profit_category
    ),
    final AS (
        SELECT
            source,
            d_year,
            d_month_seq,
            profit_category,
            total_net_profit,
            total_quantity,
            row_cnt,
            LAG(total_net_profit) OVER (PARTITION BY source ORDER BY d_year, d_month_seq) AS prev_month_profit
        FROM agg_final
    )
SELECT
    source,
    d_year,
    d_month_seq,
    profit_category,
    total_net_profit,
    total_quantity,
    row_cnt,
    prev_month_profit,
    total_net_profit - COALESCE(prev_month_profit, 0) AS profit_change
FROM final
ORDER BY source, d_year, d_month_seq
