/* goal: Analyze return amounts and inventory levels per warehouse and brand for the year 2001, highlighting high‑value returns, color‑based return amounts, and ranking warehouses by total return amount. */
WITH base AS (
    SELECT
        cc.cc_call_center_id,
        ws.web_site_id,
        cp.cp_catalog_page_id,
        ca_refund.ca_address_id AS refund_address_id,
        cd_refund.cd_demo_sk AS refund_demo_sk,
        ca_return.ca_address_id AS returning_address_id,
        cd_return.cd_demo_sk AS returning_demo_sk,
        w.w_warehouse_name,
        w.w_county,
        i.i_brand,
        i.i_color,
        d_ret.d_year,
        t.t_hour,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        inv.inv_quantity_on_hand,
        p.p_discount_active,
        r.r_reason_desc
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_refund ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_demographics cd_refund ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN customer_address ca_return ON wr.wr_returning_addr_sk = ca_return.ca_address_sk
    JOIN customer_demographics cd_return ON wr.wr_returning_cdemo_sk = cd_return.cd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                       AND inv.inv_date_sk = d_ret.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
                      AND p.p_start_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_ret.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d_ret.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND w.w_county = 'Fairfield County'
      AND p.p_discount_active = 'Y'
      AND r.r_reason_desc LIKE '%damaged%'
      AND ws.web_mkt_desc LIKE '%technical%'
),
agg AS (
    SELECT
        w_warehouse_name,
        w_county,
        i_brand,
        i_color,
        d_year,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand,
        COUNT(*) AS return_count,
        SUM(CASE WHEN i_color = 'Red' THEN wr_return_amt ELSE 0 END) AS red_return_amt
    FROM base
    GROUP BY w_warehouse_name, w_county, i_brand, i_color, d_year
)
SELECT
    a.w_warehouse_name,
    a.w_county,
    a.i_brand,
    a.i_color,
    a.d_year,
    a.total_return_amt,
    a.total_qty_on_hand,
    a.return_count,
    a.red_return_amt,
    a.total_return_amt / NULLIF(a.total_qty_on_hand, 0) AS return_per_qty,
    ROW_NUMBER() OVER (PARTITION BY a.w_warehouse_name ORDER BY a.total_return_amt DESC) AS rn
FROM agg a
WHERE a.total_return_amt > 1000
ORDER BY a.total_return_amt DESC
LIMIT 100
