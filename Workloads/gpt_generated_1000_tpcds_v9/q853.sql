WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        d.d_date,
        d.d_date_sk,
        d.d_year,
        s.s_store_id,
        s.s_state,
        sr.sr_return_amt,
        sr.sr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss,
        inv.inv_quantity_on_hand,
        cc.cc_gmt_offset,
        cp.cp_catalog_number,
        wp.wp_image_count,
        ws.web_name
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
            AND ss.ss_item_sk = sr.sr_item_sk
            AND ss.ss_store_sk = sr.sr_store_sk
        LEFT JOIN web_returns wr ON ss.ss_item_sk = wr.wr_item_sk
            AND ss.ss_sold_date_sk = wr.wr_returned_date_sk
        LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
            AND inv.inv_date_sk = d.d_date_sk
        LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
        LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
        LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND s.s_state = 'CA'
        AND i.i_category = 'Women'
        AND wp.wp_image_count > 3
        AND inv.inv_quantity_on_hand > 0
        AND cc.cc_gmt_offset BETWEEN -5 AND 0
        AND cp.cp_catalog_number > 0
)
SELECT
    d_date,
    s_store_id,
    i_item_id,
    i_category,
    i_brand,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(COALESCE(sr_return_amt, 0)) AS total_store_return_amt,
    SUM(COALESCE(wr_return_amt, 0)) AS total_web_return_amt,
    SUM(COALESCE(inv_quantity_on_hand, 0)) AS total_inventory_quantity,
    CASE WHEN SUM(ss_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_level,
    DENSE_RANK() OVER (PARTITION BY i_category ORDER BY SUM(ss_net_profit) DESC) AS profit_rank_by_category,
    ROW_NUMBER() OVER (ORDER BY SUM(ss_net_profit) DESC) AS overall_profit_rank,
    (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_sold_date_sk = d_date_sk) AS sales_count_same_day
FROM
    base
GROUP BY
    CUBE (d_date, d_date_sk, s_store_id, i_item_id, i_category, i_brand)
HAVING
    SUM(ss_net_profit) > 0
ORDER BY
    total_net_profit DESC,
    profit_rank_by_category
LIMIT 100
