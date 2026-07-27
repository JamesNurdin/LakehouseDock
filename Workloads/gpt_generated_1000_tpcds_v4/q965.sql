WITH sales_agg AS (
    SELECT
        i.i_item_id               AS i_item_id,
        d.d_year                  AS d_year,
        ib.ib_income_band_sk      AS income_band_sk,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM
        date_dim d
        JOIN catalog_sales cs               ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN catalog_page cp                ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN item i                         ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p                    ON cs.cs_promo_sk = p.p_promo_sk
        JOIN ship_mode sm                   ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w                    ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN customer c                     ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib                ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca           ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN inventory inv                  ON inv.inv_date_sk = d.d_date_sk
                                          AND inv.inv_item_sk = i.i_item_sk
                                          AND inv.inv_warehouse_sk = w.w_warehouse_sk
        JOIN time_dim t                     ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN store_sales ss                 ON ss.ss_item_sk = i.i_item_sk
                                          AND ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s                        ON ss.ss_store_sk = s.s_store_sk
        JOIN web_sales ws                  ON ws.ws_item_sk = i.i_item_sk
                                          AND ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2002
        AND i.i_current_price > 20
        AND ib.ib_lower_bound >= 50000
        AND w.w_state = 'CA'
        AND sm.sm_type = 'AIR'
    GROUP BY
        i.i_item_id,
        d.d_year,
        ib.ib_income_band_sk
),
avg_sales AS (
    SELECT
        income_band_sk,
        AVG(total_catalog_sales + total_store_sales + total_web_sales) AS avg_total_sales,
        SUM(total_catalog_sales + total_store_sales + total_web_sales) AS sum_total_sales
    FROM sales_agg
    GROUP BY income_band_sk
)
SELECT
    sa.i_item_id,
    sa.d_year,
    sa.income_band_sk,
    sa.total_catalog_sales,
    sa.total_store_sales,
    sa.total_web_sales,
    (sa.total_catalog_sales + sa.total_store_sales + sa.total_web_sales) AS total_all_sales,
    AVG(sa.total_catalog_sales + sa.total_store_sales + sa.total_web_sales) OVER (PARTITION BY sa.income_band_sk) AS avg_sales_by_band,
    RANK() OVER (PARTITION BY sa.income_band_sk ORDER BY (sa.total_catalog_sales + sa.total_store_sales + sa.total_web_sales) DESC) AS sales_rank,
    av.avg_total_sales
FROM sales_agg sa
JOIN avg_sales av ON sa.income_band_sk = av.income_band_sk
WHERE (sa.total_catalog_sales + sa.total_store_sales + sa.total_web_sales) > 5000
ORDER BY sa.income_band_sk, total_all_sales DESC
LIMIT 100
