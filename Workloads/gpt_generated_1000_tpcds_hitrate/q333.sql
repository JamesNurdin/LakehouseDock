WITH base AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        i.i_item_sk,
        i.i_item_desc,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_tickets,
        CASE WHEN inv.inv_quantity_on_hand > 100 THEN 'High' ELSE 'Low' END AS stock_level,
        (SELECT avg(i2.i_current_price) FROM item i2 WHERE i2.i_brand = i.i_brand) AS brand_avg_price,
        CASE WHEN i.i_current_price > (SELECT avg(i3.i_current_price) FROM item i3) THEN 1 ELSE 0 END AS price_above_global_avg
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE
        d.d_year = 2001
        AND i.i_size IN ('large', 'medium')
        AND s.s_state = 'TX'
        AND c.c_salutation = 'Mr.'
        AND cc.cc_gmt_offset > 0
        AND inv.inv_quantity_on_hand > 0
        AND ss.ss_quantity > 1
        AND EXISTS (
            SELECT 1 FROM warehouse w2
            WHERE w2.w_warehouse_id = w.w_warehouse_id
              AND w2.w_city = 'Seattle'
        )
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        i.i_item_sk,
        i.i_item_desc,
        d.d_year,
        inv.inv_quantity_on_hand,
        i.i_brand,
        i.i_current_price
)
SELECT
    b.s_store_name,
    b.i_item_desc,
    b.total_sales,
    b.total_return_loss,
    b.return_tickets,
    b.stock_level,
    b.brand_avg_price,
    b.price_above_global_avg,
    l.recent_sales
FROM
    base b
    CROSS JOIN LATERAL (
        SELECT SUM(ss2.ss_ext_sales_price) AS recent_sales
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = b.s_store_sk
          AND ss2.ss_sold_date_sk = (
              SELECT d2.d_date_sk
              FROM date_dim d2
              WHERE d2.d_year = 2001
                AND d2.d_month_seq = 12
              LIMIT 1
          )
    ) l
WHERE
    b.total_sales > (SELECT AVG(total_sales) FROM base)
ORDER BY
    b.total_sales DESC
LIMIT 100
