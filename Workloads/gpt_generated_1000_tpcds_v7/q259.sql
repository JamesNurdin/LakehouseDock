/* goal: Analyze combined store and web sales for a specific product group and store location, showing revenue, transaction counts, and discount metrics per item and store. */
WITH filtered AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_units,
        i.i_manufact_id,
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_tax_percentage,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        ss.ss_ext_tax,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt
    FROM tpcds.item i
    JOIN tpcds.store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.store s ON s.s_store_sk = ss.ss_store_sk
    JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_units = 'Dozen'
      AND i.i_manufact_id = 212
      AND s.s_state = 'CA'
      AND s.s_tax_percentage >= 5.00
      AND ss.ss_ext_tax > 100.00
      AND ws.ws_ext_discount_amt > 500.00
)
SELECT
    i_item_id,
    i_product_name,
    s_store_name,
    s_state,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ws_net_paid) AS total_web_sales,
    COUNT(DISTINCT ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws_order_number) AS web_orders,
    AVG(ss_ext_discount_amt) AS avg_store_discount,
    AVG(ws_ext_discount_amt) AS avg_web_discount,
    MIN(ss_ext_tax) AS min_store_ext_tax,
    MAX(ws_ext_discount_amt) AS max_web_discount_amt
FROM filtered
GROUP BY i_item_id, i_product_name, s_store_name, s_state
ORDER BY total_store_sales DESC
LIMIT 100
