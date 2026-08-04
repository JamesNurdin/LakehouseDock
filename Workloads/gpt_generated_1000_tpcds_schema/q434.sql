WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity AS catalog_quantity,
        cs.cs_net_paid AS catalog_net_paid,
        cc.cc_class,
        cp.cp_catalog_page_number,
        i.i_size,
        p.p_cost,
        ss.ss_quantity AS store_quantity,
        ss.ss_net_paid AS store_net_paid,
        sr.sr_return_quantity AS store_return_quantity,
        sr.sr_return_amt AS store_return_amt,
        wr.wr_return_quantity AS web_return_quantity,
        wr.wr_fee AS web_return_fee,
        d.d_year,
        d.d_month_seq,
        ca.ca_state
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
                       AND ss.ss_sold_date_sk = d.d_date_sk
                       AND ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
                         AND sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_returned_date_sk = d.d_date_sk
                         AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                        AND wr.wr_returned_date_sk = d.d_date_sk
                        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
                        AND wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE cc.cc_class = 'medium'
      AND cp.cp_catalog_page_number BETWEEN 5 AND 20
      AND i.i_size = 'medium'
      AND p.p_cost > 100
      AND d.d_year = 2001
      AND wr.wr_fee > 20
),
joined_site AS (
    SELECT
        b.*, 
        ws.web_name,
        ws.web_gmt_offset
    FROM base b
    RIGHT OUTER JOIN web_site ws
        ON ws.web_open_date_sk = b.cs_sold_date_sk
),
agg AS (
    SELECT
        d_year,
        ca_state,
        SUM(catalog_quantity) AS total_catalog_qty,
        SUM(store_quantity) AS total_store_qty,
        SUM(CASE WHEN web_name IS NOT NULL THEN 1 ELSE 0 END) AS web_site_present,
        AVG(catalog_net_paid) AS avg_catalog_net,
        AVG(store_net_paid) AS avg_store_net
    FROM joined_site
    GROUP BY d_year, ca_state
    HAVING SUM(catalog_quantity) > 100
)
SELECT
    d_year,
    ca_state,
    total_catalog_qty,
    avg_catalog_net
FROM agg
WHERE web_site_present > 0
UNION DISTINCT
SELECT
    d_year,
    ca_state,
    total_catalog_qty,
    avg_catalog_net
FROM agg
WHERE web_site_present = 0
ORDER BY d_year DESC, ca_state ASC
LIMIT 100
