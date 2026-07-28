WITH sales_union AS (
    SELECT cs.cs_item_sk AS item_sk,
           cs.cs_ext_sales_price AS sales_amount
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
    UNION ALL
    SELECT ss.ss_item_sk,
           ss.ss_ext_sales_price
    FROM store_sales ss
    WHERE ss.ss_quantity > 5
),
base AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_color,
        i.i_brand_id,
        i.i_current_price,
        s.s_state,
        td1.t_hour AS t_hour,
        cs.cs_net_profit,
        sr.sr_net_loss,
        ss.ss_quantity,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        COALESCE(su.sales_amount, 0) AS union_sales_amount,
        cc.cc_market_manager,
        sm.sm_carrier,
        w.w_state,
        r.r_reason_desc,
        wr.wr_return_quantity
    FROM item i
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td1 ON ss.ss_sold_time_sk = td1.t_time_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim td2 ON sr.sr_return_time_sk = td2.t_time_sk
    JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w2 ON inv.inv_warehouse_sk = w2.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    JOIN time_dim td3 ON wr.wr_returned_time_sk = td3.t_time_sk
    LEFT JOIN sales_union su ON su.item_sk = i.i_item_sk
    WHERE
        s.s_state = 'CA'
        AND i.i_color = 'Blue'
        AND cc.cc_market_manager = 'John Doe'
        AND sm.sm_carrier = 'UPS'
        AND w.w_state = 'TX'
        AND td1.t_hour BETWEEN 9 AND 17
        AND i.i_current_price > (
            SELECT AVG(i2.i_current_price)
            FROM item i2
            WHERE i2.i_brand_id = i.i_brand_id
        )
        AND EXISTS (
            SELECT 1 FROM reason r3 WHERE r3.r_reason_desc LIKE '%Defective%'
        )
)
SELECT
    s_state,
    i_category,
    hour_of_day,
    SUM(cs_profit) AS sum_cs_profit,
    SUM(sr_loss) AS sum_sr_loss,
    SUM(total_sales) AS sum_sales_amount,
    SUM(total_qty) AS total_quantity,
    COUNT(DISTINCT ticket_number) AS distinct_orders,
    RANK() OVER (ORDER BY SUM(cs_profit) DESC) AS profit_rank,
    SUM(SUM(cs_profit)) OVER (PARTITION BY s_state ORDER BY SUM(cs_profit) DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_state_profit
FROM (
    SELECT
        s_state,
        i_category,
        t_hour AS hour_of_day,
        cs_net_profit AS cs_profit,
        sr_net_loss AS sr_loss,
        ss_ext_sales_price + union_sales_amount AS total_sales,
        ss_quantity AS total_qty,
        ss_ticket_number AS ticket_number
    FROM base
) a
GROUP BY s_state, i_category, hour_of_day
HAVING SUM(cs_profit) > 10000
   AND COUNT(DISTINCT ticket_number) >= 10
ORDER BY sum_cs_profit DESC
LIMIT 100
